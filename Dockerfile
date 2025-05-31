FROM alpine:3.19 AS base

# Install Redis, Unbound, AdGuard Home, and all the necessary dependencies
RUN apk update && \
    apk upgrade && \
    apk add --no-cache redis unbound busybox-suid curl build-base openssl-dev libexpat expat-dev hiredis-dev libcap-dev libevent-dev perl && \
    apk add --no-cache redis unbound busybox-suid curl build-base openssl-dev hiredis-dev expat-dev && \
    wget https://nlnetlabs.nl/downloads/unbound/unbound-latest.tar.gz && \
    mkdir unbound-latest && tar -xzf unbound-latest.tar.gz --strip-components=1 -C unbound-latest && \
    (cd unbound-latest && \
    ./configure --with-libhiredis --with-libexpat=/usr --with-libevent --enable-cachedb --disable-flto --disable-shared --disable-rpath --with-pthreads && \
    make && make install) && rm -rf unbound-latest* && \
    LATEST_VERSION="$(curl -s https://api.github.com/repos/AdguardTeam/AdGuardHome/releases/latest | grep '\"tag_name\"' | sed -E 's/.*\"([^"]+)\".*/\1/')" && \
    wget -O /tmp/AdGuardHome.tar.gz "https://github.com/AdguardTeam/AdGuardHome/releases/download/${LATEST_VERSION}/AdGuardHome_linux_amd64.tar.gz" && \
    tar -xzf /tmp/AdGuardHome.tar.gz -C /opt && rm /tmp/AdGuardHome.tar.gz


# Create some necessary folder
RUN mkdir -p /opt/adguardhome/work /config_default && \
    chmod 777 /config_default

# Copy the local config files
COPY config/ /config_default

# Script to initialize the conf
COPY init-config.sh /usr/local/bin/init-config.sh
RUN chmod +x /usr/local/bin/init-config.sh

# Ports to expose
# 53     : TCP, UDP : DNS
# 67     :      UDP : DHCP (server)
# 68     :      UDP : DHCP (client)
# 80     : TCP      : HTTP (main)
# 443    : TCP, UDP : HTTPS, DNS-over-HTTPS (incl. HTTP/3), DNSCrypt (main)
# 853    : TCP, UDP : DNS-over-TLS, DNS-over-QUIC
# 3000   : TCP, UDP : HTTP(S) (alt, incl. HTTP/3)
# 5443   : TCP, UDP : DNSCrypt (alt)
# 6060   : TCP      : HTTP (pprof)

EXPOSE 53/tcp 53/udp 67/udp 68/udp 80/tcp 443/tcp 443/udp 853/tcp\
	853/udp 3000/tcp 3000/udp 5443/tcp 5443/udp 6060/tcp

EXPOSE 6379 5053 53/tcp 53/udp 784/udp 853/tcp 3002/tcp 80/tcp 443/tcp

ENV XDG_CONFIG_HOME=/config

# Start the services
CMD ["/bin/sh", "-c", "/usr/local/bin/init-config.sh && \
    redis-server /config/redis/redis.conf & \
    unbound -d -c /config/unbound/unbound.conf & \
    /opt/AdGuardHome/AdGuardHome -c /config/AdGuardHome/AdGuardHome.yaml -w /config"]
