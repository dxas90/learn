# End-to-End Testing Documentation

This document describes the comprehensive end-to-end testing framework for the KinD Deployment workflow.

## Overview

The testing framework includes multiple layers of validation to ensure the application deploys correctly and functions as expected in a Kubernetes environment.

## Test Structure

### 1. Unit Tests (`main_test.go`)
- Basic HTTP handler tests
- Core application functionality validation
- Located in the root directory

### 2. Integration Tests (`scripts/integration-test.sh`)
- Cross-environment testing (local, Docker, Kubernetes)
- Endpoint connectivity validation
- Environment-aware test execution

### 3. End-to-End Tests (`scripts/e2e-test.sh`)
- Comprehensive KinD cluster validation
- Kubernetes resource deployment verification
- Application health and functionality testing
- Resource constraint validation

### 4. WebSocket Tests (`scripts/websocket-test.sh`)
- WebSocket connectivity testing
- Real-time communication validation
- Network accessibility checks

## Test Categories

### Cluster Validation
- ✅ Node readiness checks
- ✅ Cluster connectivity verification
- ✅ Resource availability validation

### Container Image Testing
- ✅ Image pull and execution validation
- ✅ Container startup verification
- ✅ Runtime environment checks

### Kubernetes Resource Validation
- ✅ Deployment status verification
- ✅ Service connectivity checks
- ✅ Pod health monitoring
- ✅ Replica count validation

### Application Endpoint Testing
- ✅ Health endpoint (`/healthz`) validation
- ✅ Ping endpoint (`/ping`) response verification
- ✅ Root endpoint (`/`) content validation
- ✅ HTTP status code verification

### Health Probe Testing
- ✅ Readiness probe validation
- ✅ Liveness probe verification
- ✅ Pod status monitoring

### Resource Constraint Testing
- ✅ Memory limit verification
- ✅ CPU request validation
- ✅ Resource usage monitoring (when metrics available)

### WebSocket Testing
- ✅ WebSocket port accessibility
- ✅ Connection establishment verification
- ✅ Real-time communication testing

## Test Execution

### Automated (CI/CD)
The tests are automatically executed in the GitHub Actions workflow:

```yaml
- name: "Run Comprehensive E2E Tests"
  run: ./scripts/e2e-test.sh

- name: "Run WebSocket Tests"
  run: ./scripts/websocket-test.sh
```

### Manual Execution

#### Local Integration Testing
```bash
./scripts/integration-test.sh
```

#### KinD E2E Testing
```bash
# Requires active KinD cluster with deployed application
./scripts/e2e-test.sh
```

#### WebSocket Testing
```bash
# Requires active KinD cluster with deployed application
./scripts/websocket-test.sh
```

## Test Features

### Comprehensive Logging
- Color-coded output for easy debugging
- Structured logging with timestamps
- Detailed error reporting

### Automatic Cleanup
- Test resource cleanup on completion
- Background process termination
- Temporary resource removal

### Error Handling
- Graceful failure handling
- Detailed error diagnostics
- Debug information collection

### Retry Logic
- Configurable retry attempts
- Intelligent backoff strategies
- Timeout management

## Validation Points

### Pre-Deployment
1. **Image Build Validation**
   - Docker image compilation
   - Container registry accessibility
   - Image loading into KinD cluster

2. **Cluster Preparation**
   - Node readiness verification
   - Network connectivity checks
   - Resource availability confirmation

### Post-Deployment
1. **Resource Validation**
   - All Kubernetes resources deployed
   - Correct replica counts
   - Service endpoints accessible

2. **Application Health**
   - All pods in Running state
   - Health probes passing
   - No crash loops detected

3. **Functional Testing**
   - All HTTP endpoints responding
   - Expected response content
   - WebSocket connectivity

4. **Performance Validation**
   - Resource usage within limits
   - Response time validation
   - Connection stability

## Debugging and Troubleshooting

### Debug Information Collection
When tests fail, the following information is automatically collected:

- Cluster information and node status
- All Kubernetes resources with detailed output
- Pod descriptions and logs
- Recent cluster events
- Container status and restart counts

### Common Issues and Solutions

#### Image Pull Failures
- Verify image exists in registry
- Check network connectivity
- Validate KinD cluster configuration

#### Pod Startup Issues
- Review resource requests and limits
- Check init container logs
- Validate ConfigMap and Secret references

#### Service Connectivity Problems
- Verify service selector labels
- Check pod labels match service selector
- Validate port configurations

#### Health Probe Failures
- Review probe configuration
- Check application startup time
- Validate endpoint accessibility

## Test Configuration

### Environment Variables
- `APP_NAME`: Application name (default: "learn")
- `NAMESPACE`: Kubernetes namespace (default: "default")
- `SERVICE_NAME`: Service name (default: "learn")
- `TIMEOUT_SECONDS`: Test timeout (default: 300)

### Customization
Tests can be customized by modifying the configuration variables at the top of each test script.

## Continuous Improvement

The testing framework is designed to be:
- **Extensible**: Easy to add new test cases
- **Maintainable**: Clear structure and documentation
- **Reliable**: Robust error handling and retry logic
- **Informative**: Comprehensive logging and reporting

## Best Practices

1. **Run tests in isolated environments**
2. **Review test output regularly**
3. **Update tests when adding new features**
4. **Monitor test execution times**
5. **Keep test dependencies minimal**

## Contributing to Tests

When adding new features:
1. Add corresponding unit tests
2. Update integration tests if needed
3. Consider e2e test scenarios
4. Update this documentation

## Test Reports

Each test run generates reports with:
- Test execution summary
- Environment details
- Resource status
- Performance metrics
- Failure diagnostics (if any)

This comprehensive testing framework ensures reliable deployments and helps maintain application quality across different environments.