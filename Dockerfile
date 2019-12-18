FROM index.docker.io/gesquive/go-builder:latest AS builder

ENV APP=ghost
ARG TARGETARCH
ARG TARGETOS
ARG TARGETVARIANT

COPY dist/ /dist/
RUN copy-release

FROM scratch
LABEL maintainer="Gus Esquivel <gesquive@gmail.com>"

# Import from builder
COPY --from=builder /usr/share/zoneinfo /usr/share/zoneinfo
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=builder /etc/passwd /etc/passwd

COPY --from=builder /app/${APP} /app/

# Use an unprivileged user
USER runner

ENTRYPOINT ["/app/ghost"]
