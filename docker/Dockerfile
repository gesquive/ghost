FROM gesquive/go-builder:latest AS builder

ENV APP=ghost

# This requires that `make release-snapshot` be called first
COPY dist/ /dist/
RUN copy-release

RUN mkdir -p /etc/${APP}
COPY docker/config.yml /etc/${APP}

# =============================================================================
FROM gesquive/docker-base:latest
LABEL maintainer="Gus Esquivel <gesquive@gmail.com>"

COPY --from=builder /app/${APP} /app/
COPY --from=builder /etc/${APP} /etc/

WORKDIR /config

VOLUME /config

ENTRYPOINT ["run", "/app/ghost"]
