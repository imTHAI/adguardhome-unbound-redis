# syntax=docker/dockerfile:1.7
ARG ALPINE_VERSION=3.23

#############################################
# Stage 1: Builder (Compiles Unbound)
#############################################
FROM alpine:${ALPINE_VERSION} AS builder

ARG UNBOUND_URL="https://nlnetlabs.nl/downloads/unbound/unbound-latest.tar.gz"
ARG AGH_VERSION
ARG TARGETARCH

WORKDIR /build

# Install all packages required for compiling (build-base, and -dev versions of dependencies)
RUN apk add --no-cache \
    build-base \
    curl \
    openssl-dev \
    expat-dev \
    hiredis-dev \
    libevent-dev \
    libcap-dev \
    perl \
    linux-headers \
    wget

# Compile Unbound from source with hiredis (cachedb) support
RUN set -eux; \
    wget "${UNBOUND_URL}" -O unbound.tar.gz; \
    mkdir src; \
    tar -xzf unbound.tar.gz --strip-components=1 -C src; \
    cd src; \
    ./configure \
        --prefix=/usr \
        --sysconfdir=/etc \
        --localstatedir=/var \
        --with-libhiredis \
        --with-libexpat=/usr \
        --with-libevent \
        --enable-cachedb \
        --disable-flto \
        --disable-shared \
        --with-pthreads; \
    make -j$(nproc); \
    make install DESTDIR=/build/install

# Download and unpack AdGuard Home
RUN wget -O /build/AdGuardHome.tar.gz "https://github.com/AdguardTeam/AdGuardHome/releases/download/${AGH_VERSION}/AdGuardHome_linux_${TARGETARCH}.tar.gz" && \
    mkdir -p /build/agh && \
    tar -xzf /build/AdGuardHome.tar.gz -C /build/agh

#############################################
# Stage 2: Runtime
#############################################
FROM alpine:${ALPINE_VERSION}

# Install ONLY the runtime libraries (NO build-base, NO -dev packages)
RUN apk add --no-cache \
    tini \
    redis \
    ca-certificates \
    netcat-openbsd \
    libevent \
    hiredis \
    expat \
    libcap \
    openssl

# Create Unbound user and necessary directories
RUN addgroup -S unbound && adduser -S unbound -G unbound \
    && mkdir -p /etc/unbound/var \
    && chown -R unbound:unbound /etc/unbound

# Copy compiled Unbound files from the builder stage
COPY --from=builder /build/install/usr/sbin/unbound /usr/sbin/unbound
COPY --from=builder /build/install/usr/sbin/unbound-anchor /usr/sbin/unbound-anchor
COPY --from=builder /build/install/usr/sbin/unbound-checkconf /usr/sbin/unbound-checkconf
COPY --from=builder /build/install/usr/sbin/unbound-control /usr/sbin/unbound-control

# Copy AdGuardHome binary
COPY --from=builder /build/agh/AdGuardHome/AdGuardHome /opt/AdGuardHome/AdGuardHome

# Copy local configuration files and entrypoint script
COPY config/ /config_default
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Expose required ports
EXPOSE 53/tcp 53/udp 67/udp 68/udp 80/tcp 443/tcp 443/udp \
       853/tcp 853/udp 3000/tcp 3000/udp 5443/tcp 5443/udp \
       6060/tcp 6379 5053 784/udp 3002/tcp

# Set configuration environment variable
ENV XDG_CONFIG_HOME=/config

# Use tini as the parent process manager for signal handling
ENTRYPOINT ["/sbin/tini", "--", "/entrypoint.sh"]
