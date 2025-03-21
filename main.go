package main

import (
	"context"
	"embed"
	"flag"
	"fmt"
	"html/template"
	"log"
	"math/rand"
	"net"
	"net/http"
	"os"
	"os/signal"
	"sync"
	"syscall"
	"time"

	"github.com/gorilla/websocket"
	"github.com/prometheus/client_golang/prometheus/promhttp"
	"github.com/redis/go-redis/v9"

	"golang.org/x/sys/unix"
)

type Welcome struct {
	Name       string
	Time       string
	User       string
	RedisValue string
}

var (
	ctx          = context.Background()
	defaultValue = getEnv("DEFAULT_VALUE", "default_value")
	redisAddr    = getEnv("REDIS_ADDR", "localhost:6379")
	redisPass    = getEnv("REDIS_PASSWORD", "")
	redisDB      = getEnvInt("REDIS_DB", 0)
	channelName  = getEnv("REDIS_CHANNEL", "micropulse")

	upgrader    = websocket.Upgrader{CheckOrigin: func(r *http.Request) bool { return true }}
	clients     = make(map[*websocket.Conn]bool) // Track active WebSocket clients
	clientsLock sync.Mutex                       // Protects clients map

	rdb     *redis.Client
	rdbOnce sync.Once
)

// Get environment variable with fallback
func getEnv(key, fallback string) string {
	if value, exists := os.LookupEnv(key); exists {
		return value
	}
	return fallback
}

// Get environment variable as integer with fallback
func getEnvInt(key string, fallback int) int {
	if value, exists := os.LookupEnv(key); exists {
		var intValue int
		_, err := fmt.Sscanf(value, "%d", &intValue)
		if err == nil {
			return intValue
		}
	}
	return fallback
}

// Initialize Redis Client (singleton)
func initRedisClient() {
	rdbOnce.Do(func() {
		rdb = redis.NewClient(&redis.Options{
			Addr:     redisAddr,
			Password: redisPass,
			DB:       redisDB,
		})

		if _, err := rdb.Ping(ctx).Result(); err != nil {
			log.Println("Redis connection failed, using default value")
			rdb = nil
		}
	})
}

// Fetch value from Redis with fallback
func getValue(key string) string {
	if rdb != nil {
		val, err := rdb.Get(ctx, key).Result()
		if err == nil {
			return val
		}
		if err != redis.Nil {
			log.Println("Redis error:", err)
		}
	}
	return defaultValue
}

// Middleware for logging requests
func withLogging(next http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		log.Printf("[%s] %q from %s", r.Method, r.URL.String(), r.RemoteAddr)
		next.ServeHTTP(w, r)
	}
}

// Middleware for recovering from panics
func recoverHandler(next http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		defer func() {
			if err := recover(); err != nil {
				log.Printf("Panic: %+v", err)
				http.Error(w, http.StatusText(http.StatusInternalServerError), http.StatusInternalServerError)
			}
		}()
		next.ServeHTTP(w, r)
	}
}

// Fibonacci with iteration (efficient)
func fibonacci(n int) int {
	if n <= 1 {
		return n
	}
	a, b, i := 0, 1, 2
	for ; i <= n; i++ {
		a, b = b, a+b
	}
	return b
}

// WebSocket handler
func websocketHandler(w http.ResponseWriter, r *http.Request) {
	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Println("WebSocket upgrade failed:", err)
		return
	}

	// Register the new client
	clientsLock.Lock()
	clients[conn] = true
	clientsLock.Unlock()

	log.Println("New WebSocket connection established")

	// Handle client disconnection
	defer func() {
		clientsLock.Lock()
		delete(clients, conn)
		clientsLock.Unlock()
		conn.Close()
		log.Println("WebSocket disconnected")
	}()
}

// Broadcast messages to all WebSocket clients
func broadcastMessage(message string) {
	clientsLock.Lock()
	defer clientsLock.Unlock()

	for conn := range clients {
		err := conn.WriteMessage(websocket.TextMessage, []byte(message))
		if err != nil {
			log.Println("WebSocket send error:", err)
			conn.Close()
			delete(clients, conn)
		}
	}
}

// Redis subscription listener
func subscribeToRedis() {
	if rdb == nil {
		log.Println("Redis client is not initialized.")
		return
	}

	sub := rdb.Subscribe(ctx, channelName)
	defer sub.Close()
	ch := sub.Channel()

	log.Printf("Subscribed to Redis channel: %s", channelName)

	for msg := range ch {
		log.Printf("Broadcasting message: %s", msg.Payload)
		broadcastMessage(msg.Payload) // Send to all WebSockets
	}
}

// Handlers
func redisHandler(w http.ResponseWriter, r *http.Request) {
	value := getValue(getEnv("REDIS_VALUE", defaultValue))
	w.Header().Set("Content-Type", "application/json")
	fmt.Fprintf(w, `{"redis": "%s"}`, value)
}

func healthCheckHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	fmt.Fprint(w, `{"alive": true}`)
}

func pongHandler(response http.ResponseWriter, request *http.Request) {
	fmt.Fprintf(response, "pong")
}

func fibHandler(w http.ResponseWriter, r *http.Request) {
	rnd := rand.New(rand.NewSource(time.Now().UnixNano()))
	num := rnd.Int()
	log.Printf("Fibonacci number for: %d", num)
	fmt.Fprintf(w, "%d\n", fibonacci(num))
}

func helloHandler(w http.ResponseWriter, r *http.Request) {
	value := getValue(getEnv("REDIS_VALUE", defaultValue))
	welcome := Welcome{r.URL.Path[1:], time.Now().Format(time.Stamp), os.Getenv("USER"), value}
	templates := template.Must(template.ParseFiles("templates/index.html"))
	if err := templates.ExecuteTemplate(w, "index.html", welcome); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
	}
}

// Embed static files
//
//go:embed static/* templates
var content embed.FS

var gitCommit string

func main() {
	var (
		version bool
		port    string
	)
	flag.BoolVar(&version, "version", false, "Show version")
	flag.StringVar(&port, "port", "8080", "Port to use")
	flag.Parse()

	if version {
		fmt.Printf("Version: %s\n", gitCommit)
		return
	}

	// Initialize Redis
	initRedisClient()
	defer func() {
		if rdb != nil {
			rdb.Close()
		}
	}()

	// HTTP routes
	http.Handle("/", recoverHandler(withLogging(helloHandler)))
	http.Handle("/fib", recoverHandler(withLogging(fibHandler)))
	http.Handle("/healthz", recoverHandler(healthCheckHandler))
	http.Handle("/metrics", promhttp.Handler())
	http.Handle("/redis", recoverHandler(withLogging(redisHandler)))
	http.HandleFunc("/ws", recoverHandler(withLogging(websocketHandler))) // Register WebSocket route
	http.Handle("/static/", http.FileServer(http.FS(content)))

	// Start Redis subscriber in a Goroutine
	go subscribeToRedis()

	// Start server
	log.Printf("Starting server on port %s\n", port)
	lc := net.ListenConfig{Control: control}
	l, err := lc.Listen(context.TODO(), "tcp", ":"+port)
	if err != nil {
		log.Fatal("Failed to start server:", err)
	}
	server := &http.Server{Addr: l.Addr().String()}

	// Graceful shutdown
	exitCh := make(chan os.Signal, 1)
	signal.Notify(exitCh, syscall.SIGTERM, syscall.SIGINT)

	go func() {
		if err := http.Serve(l, nil); err != nil {
			log.Fatal("HTTP server error:", err)
		}
	}()
	<-exitCh
	server.Shutdown(context.Background())
}

// Set socket options for SO_REUSEADDR and SO_REUSEPORT
func control(network, address string, c syscall.RawConn) error {
	var err error
	c.Control(func(fd uintptr) {
		err = unix.SetsockoptInt(int(fd), unix.SOL_SOCKET, unix.SO_REUSEADDR, 1)
		if err == nil {
			err = unix.SetsockoptInt(int(fd), unix.SOL_SOCKET, unix.SO_REUSEPORT, 1)
		}
	})
	return err
}
