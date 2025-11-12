#!/bin/sh
set -e

echo "Starting initialization script..."

# --- 1. Create necessary directories ---
# We must ensure the .d directory exists for the merge logic to work
mkdir -p /config/redis /config/unbound /config/unbound/unbound.conf.d /config/AdGuardHome /config/userfilters /opt/adguardhome/work
chmod 755 /opt/adguardhome/work

# --- 2. Copy/Merge default configurations ---

# Copy Redis configuration if volume is empty
if [ -z "$(ls -A /config/redis 2>/dev/null)" ]; then
  echo "Initializing default Redis configuration files..."
  cp -r /config_default/redis/* /config/redis/
fi

# Copy AdGuardHome configuration if volume is empty
if [ -z "$(ls -A /config/AdGuardHome 2>/dev/null)" ]; then
  echo "Initializing default AdGuardHome configuration files..."
  cp -r /config_default/AdGuardHome/* /config/AdGuardHome/
fi

# # Copy unbound configuration
# 1. Check for NEW users (main config file is missing)
if [ ! -f "/config/unbound/unbound.conf" ]; then
  echo "Initializing default Unbound configuration (new user)..."
  # Copy all defaults
  cp -r /config_default/unbound/* /config/unbound/

# 2. Handle EXISTING users (main config exists)
else
  echo "Existing Unbound configuration found. Checking for upgrades..."

  NEW_FILES_STRING="dnssec.conf"
  # Add other future default files here, e.g.:
  # NEW_FILES_STRING="dnssec.conf new-privacy.conf"

  IFS=' '
  for file_name in $NEW_FILES_STRING; do
    src_file="/config_default/unbound/unbound.conf.d/$file_name"
    dest_file="/config/unbound/unbound.conf.d/$file_name"

    # Only copy the file if the source exists and destination does not
    if [ -f "$src_file" ] && [ ! -f "$dest_file" ]; then
      echo "Adding new default config file: $file_name..."
      cp "$src_file" "$dest_file"
    fi
  done
  unset IFS # Reset IFS
fi

# --- 3. Set Permissions ---
# We ensure /config is owned by root.
# Unbound will start as root to read its config, then drop privileges.
echo "Setting permissions on /config directory..."
chown -R root:root /config


# --- 4. Initialize DNSSEC Root Anchor ---
# This key lives INSIDE the container filesystem, not on the /config volume,
# to ensure the 'unbound' user can write to it.
ROOT_KEY_FILE="/etc/unbound/var/root.key"
if [ ! -f "$ROOT_KEY_FILE" ]; then
  echo "Initializing DNSSEC root trust anchor file at $ROOT_KEY_FILE..."

  # We must create a temporary resolv.conf and use the -f flag.
  TEMP_RESOLV="/tmp/temp_resolv.conf"
  echo "nameserver 1.1.1.1" > "$TEMP_RESOLV"
  echo "nameserver 1.0.0.1" >> "$TEMP_RESOLV"

  MAX_ANCHOR_RETRIES=5
  RETRY_COUNT=0
  # 'until' will retry the command *until* it succeeds (exit code 0)
  until unbound-anchor -a "$ROOT_KEY_FILE" -f "$TEMP_RESOLV" || [ $RETRY_COUNT -eq $MAX_ANCHOR_RETRIES ]; do
    RETRY_COUNT=$((RETRY_COUNT+1))
    echo "unbound-anchor failed (network not ready?), retrying ($RETRY_COUNT/$MAX_ANCHOR_RETRIES) in 2s..."
    sleep 2
  done

  rm "$TEMP_RESOLV"

  # Final check, if it still failed after retries, exit
  if [ ! -f "$ROOT_KEY_FILE" ]; then
      echo "FATAL: Could not initialize DNSSEC root anchor after $MAX_ANCHOR_RETRIES retries. Exiting."
      exit 1
  fi
  # --- End of fix ---

  echo "DNSSEC root trust anchor initialized."
else
  echo "DNSSEC root trust anchor already exists."
fi
# --- 5. Start Services ---
echo "Starting Redis server in foreground..."
redis-server /config/redis/redis.conf --daemonize no &

echo "Starting Unbound DNS server..."
unbound -d -c /config/unbound/unbound.conf &

echo "Starting AdGuardHome..."
exec /opt/AdGuardHome/AdGuardHome -c /config/AdGuardHome/AdGuardHome.yaml -w /config
