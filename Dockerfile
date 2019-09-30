FROM index.docker.io/gesquive/go-builder:latest AS builder

COPY . .

RUN make deps
RUN GOOS=linux GOARCH=amd64 make build

FROM scratch
LABEL maintainer="Gus Esquivel <gesquive@gmail.com>"

# Import from builder
COPY --from=builder /usr/share/zoneinfo /usr/share/zoneinfo
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=builder /etc/passwd /etc/passwd

COPY --from=builder /app/ghost /app/

# Use an unprivileged user
USER runuser

ENTRYPOINT ["/app/ghost"]
