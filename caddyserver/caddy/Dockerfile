ARG CADDY_VERSION
FROM docker.io/caddy:${CADDY_VERSION}-builder AS builder
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    xcaddy build \
    --with github.com/caddy-dns/cloudflare \
    --with github.com/mikucat0309/caddy-remote-host

FROM docker.io/caddy:${CADDY_VERSION}
RUN <<EOF
addgroup -S -g 998 caddy
adduser -S -h /data/caddy -H -u 998 -G caddy caddy
chown caddy:caddy /data /config
EOF
COPY --from=builder --chmod=755 /usr/bin/caddy /usr/bin/caddy
USER caddy
