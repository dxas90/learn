FROM golang:1.15.0-alpine as builder
RUN mkdir /build
ADD . /build/
WORKDIR /build
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -ldflags '-extldflags "-static"' -o main .

FROM scratch as production
COPY --from=builder /build/main /app/
EXPOSE 8080
ENTRYPOINT [ "/app/main" ]
