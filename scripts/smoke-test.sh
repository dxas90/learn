#!/bin/bash
set -euo pipefail

# Smoke test for KinD deployment
# Quick validation that the basic deployment is working

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Quick cluster health check
check_cluster_health() {
    log_info "Performing quick cluster health check..."

    if ! kubectl cluster-info >/dev/null 2>&1; then
        log_error "Cannot connect to Kubernetes cluster"
        return 1
    fi

    # Check if nodes are ready
    if ! kubectl get nodes | grep -q "Ready"; then
        log_error "No ready nodes found"
        return 1
    fi

    log_success "Cluster is healthy"
}

# Quick deployment check
check_deployment() {
    log_info "Checking deployment status..."

    if ! kubectl get deployment learn >/dev/null 2>&1; then
        log_error "Learn deployment not found"
        return 1
    fi

    # Check if deployment is available
    if kubectl get deployment learn -o jsonpath='{.status.conditions[?(@.type=="Available")].status}' | grep -q "True"; then
        log_success "Deployment is available"
    else
        log_error "Deployment is not available"
        return 1
    fi
}

# Quick service check
check_service() {
    log_info "Checking service status..."

    if ! kubectl get service learn >/dev/null 2>&1; then
        log_error "Learn service not found"
        return 1
    fi

    local cluster_ip=$(kubectl get service learn -o jsonpath='{.spec.clusterIP}')
    if [[ -n "${cluster_ip}" && "${cluster_ip}" != "None" ]]; then
        log_success "Service has cluster IP: ${cluster_ip}"
    else
        log_error "Service does not have a valid cluster IP"
        return 1
    fi
}

# Quick endpoint test
quick_endpoint_test() {
    log_info "Running quick endpoint test..."

    # Get service cluster IP directly (more reliable than DNS lookup)
    local service_ip=$(kubectl get service learn -o jsonpath='{.spec.clusterIP}')
    local service_port=$(kubectl get service learn -o jsonpath='{.spec.ports[0].port}')

    if [[ -z "${service_ip}" || "${service_ip}" == "None" ]]; then
        log_error "Could not get service cluster IP"
        return 1
    fi

    log_info "Testing health endpoint at ${service_ip}:${service_port}/healthz"

    # Create a quick test pod with direct service IP
    kubectl run smoke-test --image=curlimages/curl:latest --restart=Never --rm -i -- /bin/sh -c "
        echo \"Testing health endpoint at ${service_ip}:${service_port}/healthz\"
        if curl -s -f http://${service_ip}:${service_port}/healthz | grep -q 'alive'; then
            echo '✓ Health endpoint test passed'
        else
            echo '✗ Health endpoint test failed'
            exit 1
        fi
    " && log_success "Quick endpoint test passed" || log_error "Quick endpoint test failed"
}

# Main smoke test
main() {
    log_info "Starting smoke test for KinD deployment..."

    local exit_code=0

    check_cluster_health || exit_code=1
    check_deployment || exit_code=1
    check_service || exit_code=1
    quick_endpoint_test || exit_code=1

    if [[ ${exit_code} -eq 0 ]]; then
        log_success "🎉 Smoke test passed! Basic deployment is working."
    else
        log_error "❌ Smoke test failed! Check the logs above for details."
    fi

    return ${exit_code}
}

# Run smoke test
main "$@"
