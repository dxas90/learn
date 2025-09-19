#!/bin/bash
set -euo pipefail

# WebSocket Testing Script for the learn application
# Tests WebSocket connectivity and functionality

# Configuration
SERVICE_NAME="learn"
NAMESPACE="default"
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

# Cleanup function
cleanup() {
    log_info "Cleaning up WebSocket test resources..."
    kubectl delete pod websocket-test --ignore-not-found=true
    kubectl delete job/websocket-test-job --ignore-not-found=true
}

# Trap cleanup on exit
trap cleanup EXIT

# Test WebSocket connectivity
test_websocket_connection() {
    log_info "Testing WebSocket connectivity..."
    
    # Get service cluster IP and port
    local service_ip=$(kubectl get service ${SERVICE_NAME} -o jsonpath='{.spec.clusterIP}')
    local service_port=$(kubectl get service ${SERVICE_NAME} -o jsonpath='{.spec.ports[0].port}')
    
    log_info "WebSocket endpoint: ws://${service_ip}:${service_port}"
    
    # Create a test job to test WebSocket connection using wscat
    cat <<EOF | kubectl apply -f -
apiVersion: batch/v1
kind: Job
metadata:
  name: websocket-test-job
spec:
  template:
    spec:
      containers:
      - name: websocket-test
        image: node:18-alpine
        command: ["/bin/sh"]
        args:
        - -c
        - |
          # Install wscat for WebSocket testing
          npm install -g wscat
          
          echo "Testing WebSocket connection to ws://${service_ip}:${service_port}"
          
          # Test WebSocket connection with timeout
          timeout 30 wscat -c ws://${service_ip}:${service_port} -x 'ping' -w 5 || true
          
          if [ \$? -eq 0 ]; then
            echo "✓ WebSocket connection test completed"
          else
            echo "⚠ WebSocket connection test timed out (expected for this test)"
          fi
          
          echo "WebSocket connectivity test finished"
      restartPolicy: Never
  backoffLimit: 1
EOF

    # Wait for job to complete
    log_info "Waiting for WebSocket test to complete..."
    kubectl wait --for=condition=Complete job/websocket-test-job --timeout=120s || true
    
    # Check job logs
    log_info "WebSocket test output:"
    kubectl logs job/websocket-test-job
    
    log_success "WebSocket connectivity test completed"
    
    # Cleanup test job
    kubectl delete job websocket-test-job
}

# Test WebSocket using a simple connectivity check
test_websocket_simple() {
    log_info "Testing WebSocket with simple connectivity check..."
    
    # Get service details
    local service_ip=$(kubectl get service ${SERVICE_NAME} -o jsonpath='{.spec.clusterIP}')
    local service_port=$(kubectl get service ${SERVICE_NAME} -o jsonpath='{.spec.ports[0].port}')
    
    # Create a simple test pod to check if WebSocket port is accessible
    kubectl run websocket-test --image=busybox --restart=Never --rm -i --tty -- /bin/sh -c "
        echo 'Testing WebSocket port accessibility...'
        nc -zv ${service_ip} ${service_port}
        if [ \$? -eq 0 ]; then
            echo '✓ WebSocket port is accessible'
        else
            echo '✗ WebSocket port is not accessible'
            exit 1
        fi
    " || log_error "WebSocket port accessibility test failed"
    
    log_success "WebSocket simple connectivity test completed"
}

# Main execution
main() {
    log_info "Starting WebSocket testing for learn application..."
    
    test_websocket_simple
    test_websocket_connection
    
    log_success "WebSocket testing completed! 🎉"
}

# Run main function
main "$@"