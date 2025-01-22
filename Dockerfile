FROM golang:1.23.5-alpine as builder

RUN mkdir /build
ADD . /build/
WORKDIR /build
RUN go mod tidy && go mod vendor
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -ldflags '-extldflags "-static"' -o main .

FROM scratch as production
LABEL maintainer "Daniel Ramirez <dxas90@gmail.com>"
LABEL source "https://github.com/dxas90/learn.git"
COPY --from=builder /build/main /app/
COPY --from=builder /build/templates /app/templates
COPY --from=builder /build/static /app/static
WORKDIR /app
EXPOSE 8080
ENTRYPOINT [ "/app/main" ]
