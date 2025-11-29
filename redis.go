package main

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"sync"

	"github.com/gorilla/websocket"
	"github.com/redis/go-redis/v9"
)

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
