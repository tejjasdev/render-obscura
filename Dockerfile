# Stage 1: Build Obscura using latest Rust (supports edition2024)
FROM rust:1-bookworm AS builder

RUN apt-get update && apt-get install -y \
    pkg-config \
    libssl-dev \
    cmake \
    clang \
    libclang-dev \
    git \
    curl \
    python3 \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
RUN git clone https://github.com/h4ckf0r0day/obscura.git .

# Render Free Tier par RAM bachane ke liye single job build
ENV CARGO_BUILD_JOBS=1
RUN cargo build --release

# Stage 2: Lightweight Runtime + Caddy Proxy
FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y \
    ca-certificates \
    libssl3 \
    curl \
    gpg \
    && curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg \
    && curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | tee /etc/apt/sources.list.d/caddy-stable.list \
    && apt-get update && apt-get install -y caddy \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /app/target/release/obscura /usr/local/bin/obscura
COPY Caddyfile /etc/caddy/Caddyfile

# Obscura local port par aur Caddy Render ke $PORT par chalega
CMD ["sh", "-c", "obscura serve --host 127.0.0.1 --port 9222 --stealth & caddy run --config /etc/caddy/Caddyfile --adapter caddyfile"]
