# AWS S3 Proxy v2.0

# docker run -p 9191:80 \
#   -e AWS_REGION=us-west-2 \
# 	-e AWS_ACCESS_KEY_ID="" \
# 	-e AWS_SECRET_ACCESS_KEY="" \
# 	-e AWS_S3_BUCKET="" \
# 	-e BASIC_AUTH_USER="admin" \
# 	-e BASIC_AUTH_PASS="password" \
# 	-e DIRECTORY_LISTINGS=true \
# 	-e ACCESS_LOG=true \
# 	-e DIRECTORY_LISTINGS_FORMAT=html \
# stevelacy/s3-proxy:latest

FROM golang:1.14.0-alpine3.11 AS builder
RUN apk --no-cache add gcc musl-dev git
WORKDIR /code
COPY . /code
RUN go mod download
RUN go mod verify
RUN githash=$(git rev-parse --short HEAD 2>/dev/null) \
    && today=$(date +%Y-%m-%d --utc) \
    && CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
    -ldflags '-s -w -X main.ver=${APP_VERSION} -X main.commit=${githash} -X main.date=${today}' \
    -o /app

FROM alpine:3.11 AS libs
RUN apk --no-cache add ca-certificates

FROM scratch
COPY --from=libs /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=builder /app /aws-s3-proxy
ENTRYPOINT ["/aws-s3-proxy"]
