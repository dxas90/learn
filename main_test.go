package main

import (
	"net/http"
	"net/http/httptest"
	"os"
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestGetEnv(t *testing.T) {
	// Test with existing env var
	os.Setenv("TEST_VAR", "test_value")
	defer os.Unsetenv("TEST_VAR")
	result := getEnv("TEST_VAR", "fallback")
	assert.Equal(t, "test_value", result)

	// Test with non-existing env var
	result = getEnv("NON_EXISTENT_VAR", "fallback")
	assert.Equal(t, "fallback", result)
}

func TestGetEnvInt(t *testing.T) {
	// Test with valid integer
	os.Setenv("TEST_INT", "42")
	defer os.Unsetenv("TEST_INT")
	result := getEnvInt("TEST_INT", 10)
	assert.Equal(t, 42, result)

	// Test with invalid integer
	os.Setenv("TEST_INVALID_INT", "not_a_number")
	defer os.Unsetenv("TEST_INVALID_INT")
	result = getEnvInt("TEST_INVALID_INT", 10)
	assert.Equal(t, 10, result)

	// Test with non-existing env var
	result = getEnvInt("NON_EXISTENT_INT", 10)
	assert.Equal(t, 10, result)
}

func TestFibonacci(t *testing.T) {
	tests := []struct {
		input    int
		expected int
	}{
		{0, 0},
		{1, 1},
		{2, 1},
		{3, 2},
		{4, 3},
		{5, 5},
		{6, 8},
		{10, 55},
	}

	for _, tt := range tests {
		result := fibonacci(tt.input)
		assert.Equal(t, tt.expected, result, "fibonacci(%d) should equal %d", tt.input, tt.expected)
	}
}

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
	assert.Contains(t, w.Body.String(), "true")
}

func TestRedisHandler(t *testing.T) {
	handler := http.HandlerFunc(redisHandler)
	w := httptest.NewRecorder()
	req, _ := http.NewRequest("GET", "/redis", nil)
	handler.ServeHTTP(w, req)

	assert.Equal(t, 200, w.Code)
	assert.Contains(t, w.Body.String(), "redis")
	// Should contain JSON
	assert.Contains(t, w.Body.String(), "{")
	assert.Contains(t, w.Body.String(), "}")
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

func TestWithLoggingMiddleware(t *testing.T) {
	// Create a simple handler to wrap
	handler := withLogging(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		w.Write([]byte("test"))
	})

	w := httptest.NewRecorder()
	req, _ := http.NewRequest("GET", "/test", nil)
	handler.ServeHTTP(w, req)

	assert.Equal(t, 200, w.Code)
	assert.Equal(t, "test", w.Body.String())
}

func TestRecoverHandlerMiddleware(t *testing.T) {
	// Create a handler that panics
	handler := recoverHandler(func(w http.ResponseWriter, r *http.Request) {
		panic("test panic")
	})

	w := httptest.NewRecorder()
	req, _ := http.NewRequest("GET", "/test", nil)

	// Should not panic, but return 500
	assert.NotPanics(t, func() {
		handler.ServeHTTP(w, req)
	})

	assert.Equal(t, http.StatusInternalServerError, w.Code)
}
