# Stage 1: Build Obscura from source
FROM rust:1.83-slim-bookworm AS builder

RUN apt-get update && apt-get install -y \
    pkg-config libssl-dev git curl python3 build-essential \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
RUN git clone https://github.com/h4ckf0r0day/obscura.git .
RUN cargo build --release

# Stage 2: Minimal Runtime + Caddy for Auth & Port Binding
FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y \
    ca-certificates libssl3 curl debian-keyring debian-archive-keyring apt-transport-https \
    && curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg \
    && curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | tee /etc/apt/sources.list.d/caddy-stable.list \
    && apt-get update && apt-get install -y caddy \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /app/target/release/obscura /usr/local/bin/obscura
COPY Caddyfile /etc/caddy/Caddyfile

# Obscura internal port 9222 par chalega, aur Caddy Render ke $PORT par traffic lega
CMD obscura serve --host 127.0.0.1 --port 9222 --stealth & caddy run --config /etc/caddy/Caddyfile --adapter caddyfile
