FROM alpine:3.22 AS base
ARG TARGETARCH

# Define a build-time argument for the AdGuardHome version.
ARG AGH_VERSION

# Install Redis, Unbound, AdGuard Home, and necessary dependencies.
# netcat-openbsd is added to enable the startup check in entrypoint.sh.
# --> MODIFICATION : Ajout de "tini"
RUN apk update && apk upgrade && \
    apk add --no-cache tini redis unbound busybox-suid curl build-base openssl-dev \
    libexpat expat-dev hiredis-dev libcap-dev libevent-dev perl netcat-openbsd && \
    \
    # Compile Unbound with cachedb support
    wget https://nlnetlabs.nl/downloads/unbound/unbound-latest.tar.gz && \
    mkdir unbound-latest && tar -xzf unbound-latest.tar.gz --strip-components=1 -C unbound-latest && \
    (cd unbound-latest && \
    ./configure --with-libhiredis --with-libexpat=/usr --with-libevent --enable-cachedb --disable-flto --disable-shared --disable-rpath --with-pthreads && \
    make -j8 && make install) && rm -rf unbound-latest* && \
    \
    # Create unbound's variable data directory and grant ownership to the 'unbound' user.
    # This prevents 'Permission denied' errors when Unbound updates root.key.
    mkdir -p /etc/unbound/var && chown -R unbound:unbound /etc/unbound/var && \
    \
    # Download AdGuard Home
    wget -O /tmp/AdGuardHome.tar.gz "https://github.com/AdguardTeam/AdGuardHome/releases/download/${AGH_VERSION}/AdGuardHome_linux_${TARGETARCH}.tar.gz" && \
    tar -xzf /tmp/AdGuardHome.tar.gz -C /opt && rm /tmp/AdGuardHome.tar.gz

# Copy configuration files from local source
COPY config/ /config_default

# Copy the new entrypoint script and make it executable
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Expose required ports for various services
EXPOSE 53/tcp 53/udp 67/udp 68/udp 80/tcp 443/tcp 443/udp \
       853/tcp 853/udp 3000/tcp 3000/udp 5443/tcp 5443/udp \
       6060/tcp 6379 5053 784/udp 3002/tcp

# Set configuration environment variable
ENV XDG_CONFIG_HOME=/config

# Use the new entrypoint script as the container entrypoint
ENTRYPOINT ["/sbin/tini", "--", "/entrypoint.sh"]
