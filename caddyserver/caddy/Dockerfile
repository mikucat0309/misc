FROM quay.io/hummingbird/xcaddy:latest AS builder
ARG CADDY_VERSION
RUN --mount=type=cache,mode=777,target=/go \
    --mount=type=cache,mode=777,target=/cache \
    xcaddy build "${CADDY_VERSION}" \
    --with github.com/caddy-dns/cloudflare

FROM quay.io/hummingbird/core-runtime:latest
COPY --from=builder /caddy/caddy /usr/bin/caddy
USER ${CONTAINER_DEFAULT_USER}
ENTRYPOINT ["/usr/bin/caddy"]
