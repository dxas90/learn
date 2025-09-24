# Earthly Build Documentation

This repository includes an `Earthfile` for building the Learn application using [Earthly](https://earthly.dev/).

## Available Targets

### `+deps`
Downloads and caches Go module dependencies.

### `+build`
Builds the Learn application as a static binary with optimizations.
- Output: `build/learn` binary
- Also outputs static files and templates

### `+vendor`
Creates a vendor directory with all dependencies.
- Output: `vendor/` directory

### `+docker`
Builds a minimal Docker image from scratch.
- Base: `scratch` (minimal container)
- Image: `dxas90/learn:latest`
- Exposed port: 8080

### `+unit-test`
Runs Go unit tests for the application.

### `+integration-test`
Runs basic integration tests by starting the application and testing endpoints.

### `+lint`
Runs code quality checks:
- `go fmt` formatting check
- `go vet` static analysis
- `staticcheck` (optional)

### `+all`
Runs all targets in the correct order:
1. Lint checks
2. Unit tests
3. Build
4. Integration tests
5. Docker image

### `+dev`
Builds a development image for local testing.

## Usage Examples

```bash
# Build everything
earthly +all

# Just build the binary
earthly +build

# Run tests only
earthly +unit-test
earthly +integration-test

# Build Docker image
earthly +docker

# Lint code
earthly +lint

# Development image
earthly +dev
```

## Prerequisites

1. Install [Earthly](https://earthly.dev/get-earthly)
2. Have Docker running
3. Earthly will handle Go dependencies automatically

## Features

- **Multi-stage builds**: Efficient caching and layer reuse
- **Static binary**: No external dependencies in final image
- **Comprehensive testing**: Unit and integration tests
- **Code quality**: Automated linting and formatting checks
- **Optimized images**: Minimal scratch-based container
- **Development support**: Local development image target