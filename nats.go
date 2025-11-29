package main

import (
	"context"
	"fmt"
	"log"
	"math/rand"
	"os"
	"strconv"
	"time"

	"github.com/nats-io/nats.go"
)

// NatsResponse is a function type that processes NATS messages and returns a response
type NatsResponse func(string) string

func getNatsURL() string {
	if url := os.Getenv("NATS_URL"); url != "" {
		return url
	}
	return nats.DefaultURL
}

// NatsSubscribe initializes NATS subscriptions if NATS_SUBSCRIBE environment variable is true
func NatsSubscribe() {
	if os.Getenv("NATS_SUBSCRIBE") == "true" {
		ctx, cancel := context.WithCancel(context.Background())
		defer cancel()

		subscribe(ctx, "learn.hello", func(message string) string {
			return "I'm learning Go and I'm loving it!"
		})
		subscribe(ctx, "ci.learn", func(message string) string {
			return "Hello from the CI/CD."
		})
		subscribe(ctx, "random.request", func(message string) string {
			number, err := strconv.Atoi(message)
			if err != nil {
				return fmt.Sprintf("%s is not a number", message)
			}
			rnd := rand.New(rand.NewSource(int64(number)))
			return strconv.Itoa(rnd.Int())
		})
	}
}

// NatsPublishLoop continuously publishes messages to NATS if NATS_PUBLISH environment variable is true
func NatsPublishLoop() {
	if os.Getenv("NATS_PUBLISH") == "true" {
		for {
			if err := natsPublish("ping", "Learning here. this is learn.hello channel."); err != nil {
				log.Printf("error publishing message: %v", err)
			}
			time.Sleep(1 * time.Minute)
		}
	}
}

func natsPublish(channel, message string) error {
	nc, err := nats.Connect(getNatsURL())
	if err != nil {
		return err
	}
	defer nc.Close()

	log.Printf("publishing message: %s\n", message)
	return nc.Publish(channel, []byte(message))
}

func subscribe(ctx context.Context, channel string, fn NatsResponse) {
	nc, err := nats.Connect(getNatsURL())
	if err != nil {
		log.Fatalf("error connecting to NATS: %v", err)
	}
	defer nc.Close()

	messages := make(chan *nats.Msg, 1000)
	subscription, err := nc.ChanSubscribe(channel, messages)
	if err != nil {
		log.Fatalf("failed to subscribe to subject: %v", err)
	}
	defer func() {
		subscription.Unsubscribe()
		close(messages)
	}()

	for {
		select {
		case <-ctx.Done():
			log.Println("exiting from the message subscriber")
			return
		case message := <-messages:
			log.Printf("received message: %s\n", string(message.Data))
			response := fn(string(message.Data))
			if err := message.Respond([]byte(response)); err != nil {
				log.Printf("error responding to message: %v", err)
			}
		}
	}
}
