FROM golang:1.25.1-alpine AS builder

RUN mkdir /build
ADD . /build/
WORKDIR /build
# Use vendor directory to avoid network issues
RUN CGO_ENABLED=0 GOOS=linux go build -mod=vendor -a -installsuffix cgo -ldflags '-extldflags "-static"' -o main .

FROM scratch AS production
ARG CREATED="0000-00-00T00:00:00Z"
LABEL org.opencontainers.image.authors="Daniel Ramirez <dxas90@gmail.com>" \
    org.opencontainers.image.created=${CREATED} \
    org.opencontainers.image.description="A container image to learn." \
    org.opencontainers.image.licenses="MIT" \
    org.opencontainers.image.source=https://github.com/dxas90/learn \
    org.opencontainers.image.title="learn Image" \
    org.opencontainers.image.version="1.0.0"
COPY --from=builder /build/main /app/
COPY --from=builder /build/templates /app/templates
COPY --from=builder /build/static /app/static
WORKDIR /app
EXPOSE 8080
ENTRYPOINT [ "/app/main" ]
