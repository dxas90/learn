# Testing Framework for KinD Deployment

This directory contains comprehensive testing scripts for validating the KinD (Kubernetes in Docker) deployment workflow.

## Quick Start

### Run All Tests (Recommended)
```bash
# Requires active KinD cluster with deployed application
./scripts/smoke-test.sh          # Quick validation (30 seconds)
./scripts/e2e-test.sh           # Comprehensive testing (2-3 minutes)
./scripts/websocket-test.sh     # WebSocket validation (1 minute)
```

### Local Development Testing
```bash
./scripts/integration-test.sh   # Cross-environment testing
```

## Test Scripts Overview

### 🚀 `smoke-test.sh`
**Quick deployment validation** - Run this first!
- ⚡ Fast execution (~30 seconds)
- ✅ Basic cluster health check
- ✅ Deployment and service validation
- ✅ Quick endpoint connectivity test

### 🔬 `e2e-test.sh` 
**Comprehensive end-to-end testing** - The main validation suite
- 🏗️ Cluster readiness validation
- 📦 Container image testing
- ☸️ Kubernetes resource verification
- 🌐 Application endpoint testing
- 🔍 Health probe validation
- 📊 Resource constraint checking
- 🧹 Automatic cleanup

### 🔌 `websocket-test.sh`
**WebSocket connectivity testing** - Real-time communication validation
- 🔗 Port accessibility checks
- ⚡ Connection establishment testing
- 💬 WebSocket communication validation

### 🔧 `integration-test.sh`
**Cross-environment testing** - Local development support
- 🏠 Local application testing
- 🐳 Docker container validation
- ☸️ Kubernetes deployment testing
- 🎯 Environment-aware execution

## Test Execution Matrix

| Environment | Smoke | E2E | WebSocket | Integration |
|-------------|-------|-----|-----------|-------------|
| Local Dev   | ❌    | ❌  | ❌        | ✅          |
| KinD Cluster| ✅    | ✅  | ✅        | ✅          |
| CI/CD       | ✅    | ✅  | ✅        | ❌          |

## Features

### 🎨 Rich Output
- Color-coded logging (Blue=Info, Green=Success, Red=Error)
- Structured output with timestamps
- Progress indicators and status reports

### 🛡️ Robust Error Handling
- Automatic resource cleanup
- Graceful failure handling
- Comprehensive debug information collection
- Configurable timeouts and retries

### ⚙️ Configurable
Each script supports environment variables for customization:
```bash
export APP_NAME="learn"           # Application name
export NAMESPACE="default"       # Kubernetes namespace
export SERVICE_NAME="learn"      # Service name
export TIMEOUT_SECONDS=300       # Test timeout
```

## Validation Coverage

### ✅ Pre-Deployment Checks
- Docker image build validation
- Cluster connectivity verification
- Resource availability confirmation

### ✅ Deployment Validation
- All Kubernetes resources deployed correctly
- Correct replica counts and pod status
- Service endpoints accessible
- ConfigMaps and Secrets properly mounted

### ✅ Application Health
- All pods in Running state
- Health probes (readiness/liveness) passing
- No crash loops or restart issues
- Resource usage within defined limits

### ✅ Functional Testing
- HTTP endpoints responding correctly
  - `/healthz` - Health check endpoint
  - `/ping` - Simple ping response
  - `/` - Root application endpoint
- WebSocket connectivity working
- Expected response content validation

## CI/CD Integration

The tests are automatically executed in GitHub Actions:

```yaml
# .github/workflows/k8s-deployment.yml
- name: "Run Smoke Test"
  run: ./scripts/smoke-test.sh

- name: "Run Comprehensive E2E Tests"  
  run: ./scripts/e2e-test.sh

- name: "Run WebSocket Tests"
  run: ./scripts/websocket-test.sh
```

## Debugging Failed Tests

### 🔍 Debug Information Collection
When tests fail, debug information is automatically collected:
- Cluster information and node status
- All Kubernetes resources with detailed output
- Pod descriptions and logs
- Recent cluster events
- Container status and restart counts

### 🐛 Common Issues and Solutions

**Image Pull Failures**
```bash
# Check if image exists and is accessible
kubectl describe pods | grep -A5 "Failed to pull image"
```

**Pod Startup Issues**
```bash
# Check resource constraints and init containers
kubectl describe pod <pod-name>
kubectl logs <pod-name> --previous
```

**Service Connectivity Problems**
```bash
# Verify service selectors match pod labels
kubectl get pods --show-labels
kubectl describe service learn
```

**Health Probe Failures**
```bash
# Check probe configuration and endpoints
kubectl describe deployment learn
curl -v http://<pod-ip>:8080/healthz
```

## Best Practices

### 🎯 Test Strategy
1. **Start with smoke tests** - Quick validation
2. **Run comprehensive E2E** - Full validation  
3. **Add WebSocket tests** - Real-time features
4. **Use integration tests** - Local development

### 📊 Monitoring
- Monitor test execution times
- Review logs for warnings
- Track failure patterns
- Update tests for new features

### 🔄 Maintenance
- Keep tests updated with application changes
- Review and optimize test timeouts
- Ensure cleanup procedures are working
- Document test failures and resolutions

## Contributing

When adding new features to the application:

1. **Add corresponding tests** in the appropriate script
2. **Update test documentation** 
3. **Verify all test scenarios** work correctly
4. **Test in different environments** (local, CI/CD)

## Test Reports

Each test run provides:
- ✅ Execution summary with pass/fail status
- 📝 Environment details and configuration
- 📊 Resource status and performance metrics  
- 🔍 Failure diagnostics (when applicable)

---

For detailed information about the testing framework, see [docs/testing.md](../docs/testing.md).

## Quick Reference

```bash
# Quick health check
./scripts/smoke-test.sh

# Full validation suite  
./scripts/e2e-test.sh

# WebSocket testing
./scripts/websocket-test.sh

# Local development
./scripts/integration-test.sh

# View logs
kubectl logs -f deployment/learn

# Debug pod issues
kubectl describe pods -l app=gitops-k8s
```