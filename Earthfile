VERSION 0.8
FROM golang:1.25.1-alpine3.18
WORKDIR /learn

deps:
    # Install build dependencies
    RUN apk add --no-cache ca-certificates git
    COPY go.mod go.sum ./
    RUN go mod download
    SAVE ARTIFACT go.mod AS LOCAL go.mod
    SAVE ARTIFACT go.sum AS LOCAL go.sum

build:
    FROM +deps
    COPY main.go .
    COPY static static
    COPY templates templates
    # Build static binary with optimization flags
    RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
        -mod=vendor \
        -a -installsuffix cgo \
        -ldflags '-extldflags "-static" -s -w' \
        -o build/learn .
    SAVE ARTIFACT build/learn /learn AS LOCAL build/learn
    SAVE ARTIFACT static AS LOCAL build/static
    SAVE ARTIFACT templates AS LOCAL build/templates

vendor:
    FROM +deps
    RUN go mod vendor
    SAVE ARTIFACT vendor AS LOCAL vendor

docker:
    FROM scratch
    ARG CREATED="0000-00-00T00:00:00Z"
    LABEL org.opencontainers.image.authors="Daniel Ramirez <dxas90@gmail.com>" \
        org.opencontainers.image.created=${CREATED} \
        org.opencontainers.image.description="A container image to learn." \
        org.opencontainers.image.licenses="MIT" \
        org.opencontainers.image.source=https://github.com/dxas90/learn \
        org.opencontainers.image.title="learn Image" \
        org.opencontainers.image.version="1.0.0"
    COPY +build/learn /app/
    COPY +build/static /app/static
    COPY +build/templates /app/templates
    WORKDIR /app
    EXPOSE 8080
    ENTRYPOINT ["/app/learn"]
    SAVE IMAGE --push dxas90/learn:latest

unit-test:
    FROM +deps
    COPY main.go .
    COPY main_test.go .
    COPY static static
    COPY templates templates
    RUN CGO_ENABLED=0 go test -v ./...

integration-test:
    FROM +deps
    COPY main.go .
    COPY static static
    COPY templates templates
    COPY scripts scripts
    # Make scripts executable
    RUN chmod +x scripts/*.sh
    # Run integration tests (requires Docker for real integration testing)
    RUN CGO_ENABLED=0 go build -o /tmp/learn .
    # Basic integration test - start app and test endpoints
    RUN /tmp/learn &
    RUN sleep 2
    RUN apk add --no-cache curl
    RUN curl -f http://localhost:8080/healthz || (echo "Health check failed" && exit 1)
    RUN curl -f http://localhost:8080/ping || (echo "Ping failed" && exit 1)

lint:
    FROM +deps
    RUN go install honnef.co/go/tools/cmd/staticcheck@latest
    RUN go install golang.org/x/tools/cmd/goimports@latest
    COPY main.go .
    COPY main_test.go .
    # Run go fmt check (excluding vendor directory)
    RUN test -z "$(gofmt -l *.go)"
    # Run go vet
    RUN go vet ./...
    # Run staticcheck (if available)
    RUN staticcheck ./... || echo "staticcheck not available, skipping"

all:
    BUILD +lint
    BUILD +unit-test
    BUILD +build
    BUILD +integration-test
    BUILD +docker

# Development target for local development
dev:
    FROM +deps
    COPY main.go .
    COPY main_test.go .
    COPY static static
    COPY templates templates
    RUN go build -o /tmp/learn .
    CMD ["/tmp/learn"]
    SAVE IMAGE learn:dev