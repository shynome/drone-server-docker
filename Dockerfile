# docker build --rm -f docker/Dockerfile -t drone/drone .
FROM golang:1.14-alpine3.11 as Build
ARG DRONE_VERSION=v1.9.2
RUN apk add --no-cache git build-base
RUN git clone -b $DRONE_VERSION https://github.com/drone/drone.git /root/drone
WORKDIR /root/drone
RUN go mod download
RUN cd cmd/drone-server \
    && go build -tags "nolimit" -o drone-server \
    && cp drone-server /tmp/drone-server

FROM alpine:3.11 as SSL
RUN apk add -U --no-cache ca-certificates

FROM alpine:3.11
EXPOSE 80 443
VOLUME /data

RUN [ ! -e /etc/nsswitch.conf ] && echo 'hosts: files dns' > /etc/nsswitch.conf

ENV GODEBUG netdns=go
ENV XDG_CACHE_HOME /data
ENV DRONE_DATABASE_DRIVER sqlite3
ENV DRONE_DATABASE_DATASOURCE /data/database.sqlite
ENV DRONE_RUNNER_OS=linux
ENV DRONE_RUNNER_ARCH=amd64
ENV DRONE_SERVER_PORT=:80
ENV DRONE_SERVER_HOST=localhost
ENV DRONE_DATADOG_ENABLED=false
ENV DRONE_DATADOG_ENDPOINT=https://stats.drone.ci/api/v1/series

COPY --from=SSL /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=Build /tmp/drone-server /bin/

ENTRYPOINT ["/bin/drone-server"]
