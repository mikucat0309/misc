FROM quay.io/hummingbird/xcaddy:latest AS builder
ARG CADDY_VERSION
RUN --mount=type=cache,mode=777,target=/go \
    --mount=type=cache,mode=777,target=/cache \
    xcaddy build "v${CADDY_VERSION}" \
    --with github.com/caddy-dns/cloudflare

FROM scratch
COPY --from=builder /caddy/caddy /caddy
USER 65532
ENTRYPOINT ["/caddy"]
