package main

import (
	"os"
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestGetNatsURL(t *testing.T) {
	// Test default URL
	os.Unsetenv("NATS_URL")
	url := getNatsURL()
	assert.NotEmpty(t, url)

	// Test custom URL
	customURL := "nats://localhost:4222"
	os.Setenv("NATS_URL", customURL)
	defer os.Unsetenv("NATS_URL")
	url = getNatsURL()
	assert.Equal(t, customURL, url)
}

func TestNatsSubscribeEnvironmentVariable(t *testing.T) {
	// Test when NATS_SUBSCRIBE is not set
	os.Unsetenv("NATS_SUBSCRIBE")
	// Should not panic
	assert.NotPanics(t, func() {
		NatsSubscribe()
	})

	// Test when NATS_SUBSCRIBE is false
	os.Setenv("NATS_SUBSCRIBE", "false")
	defer os.Unsetenv("NATS_SUBSCRIBE")
	// Should not panic
	assert.NotPanics(t, func() {
		NatsSubscribe()
	})
}
