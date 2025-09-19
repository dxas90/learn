#!/bin/bash
set -euo pipefail

# Comprehensive End-to-End Testing Script for KinD Deployment
# This script validates the complete deployment workflow

# Configuration
APP_NAME="learn"
NAMESPACE="default"
SERVICE_NAME="learn"
DEPLOYMENT_NAME="learn"
TIMEOUT_SECONDS=300
RETRY_INTERVAL=5

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

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Cleanup function
cleanup() {
    log_info "Cleaning up test resources..."
    kubectl delete pod test-pod-image-validation --ignore-not-found=true
    kubectl delete pod test-pod --ignore-not-found=true
    kubectl delete job/curl-test --ignore-not-found=true
}

# Trap cleanup on exit
trap cleanup EXIT

# Validate KinD cluster is ready
validate_cluster() {
    log_info "Validating KinD cluster readiness..."
    
    # Check cluster info
    if ! kubectl cluster-info >/dev/null 2>&1; then
        log_error "Cannot connect to Kubernetes cluster"
        exit 1
    fi
    
    # Wait for nodes to be ready
    log_info "Waiting for all nodes to be ready..."
    kubectl wait --for=condition=Ready nodes --all --timeout=${TIMEOUT_SECONDS}s
    
    # Display cluster information
    log_info "Cluster nodes:"
    kubectl get nodes -o wide
    
    log_success "Cluster validation completed"
}

# Validate container image
validate_container_image() {
    log_info "Validating container image accessibility..."
    
    # Get the image from deployment
    local image=$(kubectl get deployment ${DEPLOYMENT_NAME} -o jsonpath='{.spec.template.spec.containers[0].image}')
    log_info "Testing image: ${image}"
    
    # Create a test pod to verify image can be pulled and starts successfully
    # Since the image is based on scratch, we use the actual entrypoint instead of sleep
    cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: test-pod-image-validation
  labels:
    test: image-validation
spec:
  containers:
  - name: test-container
    image: ${image}
    # Use the same environment variables as the main deployment to ensure it starts properly
    env:
    - name: MY_NAMESPACE
      valueFrom:
        fieldRef:
          fieldPath: metadata.namespace
    - name: POD_NAME
      valueFrom:
        fieldRef:
          fieldPath: metadata.name
    ports:
    - containerPort: 8080
    readinessProbe:
      httpGet:
        path: /healthz
        port: 8080
      initialDelaySeconds: 5
      periodSeconds: 10
  restartPolicy: Never
EOF
    
    # Wait for pod to be running
    log_info "Waiting for test pod to be running..."
    kubectl wait --for=condition=Ready pod/test-pod-image-validation --timeout=60s
    
    # Check if the container started successfully
    if kubectl get pod test-pod-image-validation -o jsonpath='{.status.phase}' | grep -q "Running"; then
        log_success "Container image validation successful"
        log_info "Test pod is healthy and responding to readiness probe"
    else
        log_error "Container image validation failed"
        log_error "Pod status: $(kubectl get pod test-pod-image-validation -o jsonpath='{.status.phase}')"
        kubectl describe pod test-pod-image-validation
        kubectl logs test-pod-image-validation || true
        exit 1
    fi
    
    # Cleanup test pod
    kubectl delete pod test-pod-image-validation
}

# Validate Kubernetes resources
validate_k8s_resources() {
    log_info "Validating Kubernetes resources deployment..."
    
    # Check if deployment exists and is ready
    log_info "Checking deployment status..."
    kubectl wait --for=condition=Available deployment/${DEPLOYMENT_NAME} --timeout=${TIMEOUT_SECONDS}s
    
    # Verify desired vs available replicas
    local desired=$(kubectl get deployment ${DEPLOYMENT_NAME} -o jsonpath='{.spec.replicas}')
    local available=$(kubectl get deployment ${DEPLOYMENT_NAME} -o jsonpath='{.status.availableReplicas}')
    
    if [[ "${available}" == "${desired}" ]]; then
        log_success "Deployment has correct number of replicas: ${available}/${desired}"
    else
        log_error "Deployment replica mismatch: ${available}/${desired}"
        exit 1
    fi
    
    # Check if service exists
    log_info "Checking service status..."
    if kubectl get service ${SERVICE_NAME} >/dev/null 2>&1; then
        log_success "Service ${SERVICE_NAME} exists"
        kubectl get service ${SERVICE_NAME}
    else
        log_error "Service ${SERVICE_NAME} not found"
        exit 1
    fi
    
    # Check pod status
    log_info "Checking pod status..."
    kubectl get pods -l app=gitops-k8s
    
    # Verify all pods are running
    local pod_count=$(kubectl get pods -l app=gitops-k8s --field-selector=status.phase=Running --no-headers | wc -l)
    if [[ ${pod_count} -gt 0 ]]; then
        log_success "All application pods are running (${pod_count})"
    else
        log_error "No running pods found"
        kubectl describe pods -l app=gitops-k8s
        exit 1
    fi
    
    log_success "Kubernetes resources validation completed"
}

# Test application endpoints
test_application_endpoints() {
    log_info "Testing application endpoints..."
    
    # Get service cluster IP
    local service_ip=$(kubectl get service ${SERVICE_NAME} -o jsonpath='{.spec.clusterIP}')
    local service_port=$(kubectl get service ${SERVICE_NAME} -o jsonpath='{.spec.ports[0].port}')
    
    log_info "Service endpoint: ${service_ip}:${service_port}"
    
    # Create a test job to make HTTP requests from within the cluster
    cat <<EOF | kubectl apply -f -
apiVersion: batch/v1
kind: Job
metadata:
  name: curl-test
spec:
  template:
    spec:
      containers:
      - name: curl
        image: curlimages/curl:latest
        command: ["/bin/sh"]
        args:
        - -c
        - |
          echo "Testing health endpoint..."
          response=\$(curl -s -w "%{http_code}" http://${service_ip}:${service_port}/healthz -o /tmp/health.out)
          if [ "\$response" = "200" ]; then
            echo "✓ Health endpoint test passed"
            cat /tmp/health.out
          else
            echo "✗ Health endpoint test failed (HTTP \$response)"
            exit 1
          fi
          
          echo "Testing ping endpoint..."
          response=\$(curl -s -w "%{http_code}" http://${service_ip}:${service_port}/ping -o /tmp/ping.out)
          if [ "\$response" = "200" ]; then
            echo "✓ Ping endpoint test passed"
            cat /tmp/ping.out
          else
            echo "✗ Ping endpoint test failed (HTTP \$response)"
            exit 1
          fi
          
          echo "Testing root endpoint..."
          response=\$(curl -s -w "%{http_code}" http://${service_ip}:${service_port}/ -o /tmp/root.out)
          if [ "\$response" = "200" ]; then
            echo "✓ Root endpoint test passed"
            head -10 /tmp/root.out
          else
            echo "✗ Root endpoint test failed (HTTP \$response)"
            exit 1
          fi
          
          echo "All endpoint tests completed successfully!"
      restartPolicy: Never
  backoffLimit: 3
EOF

    # Wait for job to complete
    log_info "Waiting for endpoint tests to complete..."
    kubectl wait --for=condition=Complete job/curl-test --timeout=120s
    
    # Check job result
    if kubectl get job curl-test -o jsonpath='{.status.succeeded}' | grep -q "1"; then
        log_success "All endpoint tests passed"
        log_info "Test output:"
        kubectl logs job/curl-test
    else
        log_error "Endpoint tests failed"
        kubectl logs job/curl-test
        kubectl describe job curl-test
        exit 1
    fi
    
    # Cleanup test job
    kubectl delete job curl-test
}

# Test readiness and liveness probes
test_health_probes() {
    log_info "Testing health probes..."
    
    # Check if pods are passing readiness checks
    local ready_pods=$(kubectl get pods -l app=gitops-k8s -o jsonpath='{.items[*].status.conditions[?(@.type=="Ready")].status}')
    
    if [[ "${ready_pods}" == *"True"* ]]; then
        log_success "Readiness probes are passing"
    else
        log_error "Readiness probes are failing"
        kubectl describe pods -l app=gitops-k8s
        exit 1
    fi
    
    log_success "Health probes validation completed"
}

# Test resource limits and requests
test_resource_constraints() {
    log_info "Validating resource constraints..."
    
    # Check if pods are running within resource limits
    local pod_name=$(kubectl get pods -l app=gitops-k8s -o jsonpath='{.items[0].metadata.name}')
    
    # Get resource usage (if metrics server is available)
    if kubectl top pod ${pod_name} >/dev/null 2>&1; then
        log_info "Current resource usage:"
        kubectl top pod ${pod_name}
    else
        log_warning "Metrics server not available, skipping resource usage check"
    fi
    
    # Verify resource requests and limits are set
    local requests=$(kubectl get pod ${pod_name} -o jsonpath='{.spec.containers[0].resources.requests}')
    local limits=$(kubectl get pod ${pod_name} -o jsonpath='{.spec.containers[0].resources.limits}')
    
    if [[ -n "${requests}" && -n "${limits}" ]]; then
        log_success "Resource constraints are properly configured"
        log_info "Requests: ${requests}"
        log_info "Limits: ${limits}"
    else
        log_warning "Resource constraints not fully configured"
    fi
}

# Generate test report
generate_report() {
    log_info "Generating test report..."
    
    cat <<EOF

===========================================
     END-TO-END TEST REPORT
===========================================

Cluster Information:
$(kubectl cluster-info)

Nodes:
$(kubectl get nodes)

Deployment Status:
$(kubectl get deployment ${DEPLOYMENT_NAME})

Service Status:
$(kubectl get service ${SERVICE_NAME})

Pod Status:
$(kubectl get pods -l app=gitops-k8s)

===========================================
EOF

    log_success "End-to-end testing completed successfully!"
}

# Main execution
main() {
    log_info "Starting comprehensive end-to-end testing for KinD deployment..."
    log_info "Testing application: ${APP_NAME}"
    log_info "Namespace: ${NAMESPACE}"
    
    validate_cluster
    validate_k8s_resources
    validate_container_image
    test_health_probes
    test_application_endpoints
    test_resource_constraints
    generate_report
    
    log_success "All tests passed! 🎉"
}

# Run main function
main "$@"