#!/bin/sh
set -e

echo "Starting initialization script..."

# Create necessary directories if they do not exist
echo "Creating necessary directories..."
mkdir -p /config/redis /config/unbound /config/AdGuardHome /config/userfilters /opt/adguardhome/work
chmod 755 /opt/adguardhome/work

# Copy default configuration files only if the directory is empty (first run)
if [ -z "$(ls -A /config/redis 2>/dev/null)" ]; then
  echo "Copying default Redis configuration files..."
  cp -r /config_default/redis/* /config/redis/
fi

if [ -z "$(ls -A /config/unbound 2>/dev/null)" ]; then
  echo "Copying default Unbound configuration files..."
  cp -r /config_default/unbound/* /config/unbound/
fi

if [ -z "$(ls -A /config/AdGuardHome 2>/dev/null)" ]; then
  echo "Copying default AdGuardHome configuration files..."
  cp -r /config_default/AdGuardHome/* /config/AdGuardHome/
fi

echo "Setting permissions on /config directory..."
chown -R root:root /config
chmod -R 755 /config

echo "Starting Redis server..."
redis-server /config/redis/redis.conf &

echo "Starting Unbound DNS server..."
unbound -d -c /config/unbound/unbound.conf &

echo "Starting AdGuardHome..."
exec /opt/AdGuardHome/AdGuardHome -c /config/AdGuardHome/AdGuardHome.yaml -w /config
