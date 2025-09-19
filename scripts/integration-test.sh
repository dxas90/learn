#!/bin/bash
set -euo pipefail

# Integration test script for the learn application
# This script can be run locally or in CI to validate application integration

# Configuration
APP_NAME="learn"
SERVICE_NAME="learn"
NAMESPACE="default"
LOCAL_PORT=8080
TIMEOUT_SECONDS=60

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running in Kubernetes or locally
check_environment() {
    if kubectl cluster-info >/dev/null 2>&1; then
        echo "k8s"
    else
        echo "local"
    fi
}

# Test application locally
test_local_application() {
    log_info "Testing application locally..."
    
    # Start the application in background
    go run main.go &
    APP_PID=$!
    
    # Wait for application to start
    sleep 5
    
    # Test endpoints
    test_endpoint "http://localhost:${LOCAL_PORT}/healthz" "Health endpoint"
    test_endpoint "http://localhost:${LOCAL_PORT}/ping" "Ping endpoint"
    test_endpoint "http://localhost:${LOCAL_PORT}/" "Root endpoint"
    
    # Kill the application
    kill $APP_PID || true
    wait $APP_PID 2>/dev/null || true
    
    log_success "Local application testing completed"
}

# Test application in Kubernetes
test_k8s_application() {
    log_info "Testing application in Kubernetes..."
    
    # Port forward to access the service
    kubectl port-forward service/${SERVICE_NAME} ${LOCAL_PORT}:8080 &
    PF_PID=$!
    
    # Wait for port forwarding to be ready
    sleep 5
    
    # Test endpoints
    test_endpoint "http://localhost:${LOCAL_PORT}/healthz" "Health endpoint (K8s)"
    test_endpoint "http://localhost:${LOCAL_PORT}/ping" "Ping endpoint (K8s)"
    test_endpoint "http://localhost:${LOCAL_PORT}/" "Root endpoint (K8s)"
    
    # Kill port forwarding
    kill $PF_PID || true
    wait $PF_PID 2>/dev/null || true
    
    log_success "Kubernetes application testing completed"
}

# Generic endpoint testing function
test_endpoint() {
    local url=$1
    local description=$2
    local max_retries=5
    local retry_count=0
    
    log_info "Testing ${description}: ${url}"
    
    while [ $retry_count -lt $max_retries ]; do
        if curl -s -f "${url}" >/dev/null; then
            log_success "${description} test passed"
            return 0
        else
            retry_count=$((retry_count + 1))
            log_info "Retry ${retry_count}/${max_retries} for ${description}"
            sleep 2
        fi
    done
    
    log_error "${description} test failed after ${max_retries} retries"
    return 1
}

# Test Docker container
test_docker_container() {
    log_info "Testing Docker container..."
    
    # Build the container
    docker build -t learn-test .
    
    # Run the container
    docker run -d -p ${LOCAL_PORT}:8080 --name learn-test-container learn-test
    
    # Wait for container to start
    sleep 10
    
    # Test endpoints
    test_endpoint "http://localhost:${LOCAL_PORT}/healthz" "Docker Health endpoint"
    test_endpoint "http://localhost:${LOCAL_PORT}/ping" "Docker Ping endpoint"
    test_endpoint "http://localhost:${LOCAL_PORT}/" "Docker Root endpoint"
    
    # Cleanup
    docker stop learn-test-container || true
    docker rm learn-test-container || true
    docker rmi learn-test || true
    
    log_success "Docker container testing completed"
}

# Run unit tests
run_unit_tests() {
    log_info "Running unit tests..."
    
    if go test -v ./...; then
        log_success "Unit tests passed"
    else
        log_error "Unit tests failed"
        return 1
    fi
}

# Run integration tests based on environment
run_integration_tests() {
    local environment=$(check_environment)
    
    log_info "Running integration tests in ${environment} environment"
    
    case $environment in
        "k8s")
            test_k8s_application
            ;;
        "local")
            test_local_application
            test_docker_container
            ;;
        *)
            log_error "Unknown environment: ${environment}"
            return 1
            ;;
    esac
}

# Generate integration test report
generate_integration_report() {
    log_info "Generating integration test report..."
    
    local environment=$(check_environment)
    
    cat <<EOF

===========================================
     INTEGRATION TEST REPORT
===========================================

Environment: ${environment}
Timestamp: $(date)
Application: ${APP_NAME}

Tests Performed:
✓ Unit tests
✓ Endpoint connectivity tests
✓ Application health checks

Environment Details:
$(if [ "$environment" = "k8s" ]; then
    echo "Kubernetes Cluster: $(kubectl cluster-info --context=$(kubectl config current-context) | head -1)"
    echo "Namespace: ${NAMESPACE}"
    echo "Service: ${SERVICE_NAME}"
else
    echo "Local environment"
    echo "Go version: $(go version)"
    echo "Docker version: $(docker --version)"
fi)

===========================================
EOF

    log_success "Integration testing completed successfully!"
}

# Main execution
main() {
    log_info "Starting integration testing for ${APP_NAME}..."
    
    # Check dependencies
    if ! command -v curl >/dev/null; then
        log_error "curl is required but not installed"
        exit 1
    fi
    
    if ! command -v go >/dev/null; then
        log_error "Go is required but not installed"
        exit 1
    fi
    
    # Run tests
    run_unit_tests
    run_integration_tests
    generate_integration_report
    
    log_success "All integration tests passed! 🎉"
}

# Cleanup function
cleanup() {
    # Kill any background processes
    jobs -p | xargs -r kill || true
    
    # Cleanup Docker containers
    docker stop learn-test-container 2>/dev/null || true
    docker rm learn-test-container 2>/dev/null || true
}

# Trap cleanup on exit
trap cleanup EXIT

# Run main function
main "$@"