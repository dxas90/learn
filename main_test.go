package main

import (
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestHelloRoute(t *testing.T) {
	handler := http.HandlerFunc(helloHandler)
	w := httptest.NewRecorder()
	req, _ := http.NewRequest("GET", "/", nil)
	handler.ServeHTTP(w, req)

	assert.Equal(t, 200, w.Code)
	assert.Contains(t, w.Body.String(), "Welcome")
}

func TestPingRoute(t *testing.T) {
	handler := http.HandlerFunc(pongHandler)

	w := httptest.NewRecorder()
	req, _ := http.NewRequest("GET", "/ping", nil)
	handler.ServeHTTP(w, req)

	assert.Equal(t, 200, w.Code)
	assert.Equal(t, "pong", w.Body.String())
}

func TestHealthRoute(t *testing.T) {
	handler := http.HandlerFunc(healthCheckHandler)
	w := httptest.NewRecorder()
	req, _ := http.NewRequest("GET", "/healthz", nil)
	handler.ServeHTTP(w, req)

	assert.Equal(t, 200, w.Code)
	assert.Contains(t, w.Body.String(), "alive")
}

func TestStackStressRoute(t *testing.T) {
	handler := http.HandlerFunc(stackStressHandler)
	w := httptest.NewRecorder()
	req, _ := http.NewRequest("GET", "/stack-stress?goroutines=2&depth=10&duration=1s", nil)
	handler.ServeHTTP(w, req)

	assert.Equal(t, 200, w.Code)
	body := w.Body.String()
	assert.Contains(t, body, "starting")
	assert.Contains(t, body, "completed")
	assert.Contains(t, body, "goroutines")
}

func TestStackStressRouteDefaultParams(t *testing.T) {
	handler := http.HandlerFunc(stackStressHandler)
	w := httptest.NewRecorder()
	req, _ := http.NewRequest("GET", "/stack-stress", nil)
	handler.ServeHTTP(w, req)

	assert.Equal(t, 200, w.Code)
	body := w.Body.String()
	assert.Contains(t, body, "starting")
	assert.Contains(t, body, "completed")
}

func TestStressStackFunction(t *testing.T) {
	// Test the stressStack function directly
	result := stressStack(5)
	assert.Equal(t, 0, result) // Function should return 0
}

func TestStackStressRouteInvalidParams(t *testing.T) {
	handler := http.HandlerFunc(stackStressHandler)
	w := httptest.NewRecorder()
	// Test with invalid parameters - should use defaults
	req, _ := http.NewRequest("GET", "/stack-stress?goroutines=invalid&depth=-1&duration=invalid", nil)
	handler.ServeHTTP(w, req)

	assert.Equal(t, 200, w.Code)
	body := w.Body.String()
	// Should use default values and still work
	assert.Contains(t, body, "starting")
	assert.Contains(t, body, "completed")
}
