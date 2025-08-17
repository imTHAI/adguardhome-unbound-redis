# 🚀 AdGuard Home + Unbound + Redis

![Docker Pulls](https://img.shields.io/docker/pulls/imthai/adguardhome-unbound-redis)
![Docker Stars](https://img.shields.io/docker/stars/imthai/adguardhome-unbound-redis)

A Docker container combining [AdGuard Home](https://github.com/AdguardTeam/AdGuardHome), [Unbound](https://unbound.docs.nlnetlabs.nl/en/latest/) (with DNS prefetching), and [Redis](https://redis.io/docs/latest/get-started/) as an in-memory caching layer — built for speed, privacy, and performance.

---

## 🔍 Why This Setup?

### ✅ Benefits of Unbound with Prefetching:
- **Faster DNS Resolution**: Frequently accessed DNS records are proactively resolved and cached.
- **Lower Latency**: Reduces delays caused by DNS lookups, especially useful for latency-sensitive applications.
- **Better Network Performance**: Prefetched responses are immediately available, reducing wait times.

### 🧠 Benefits of Using Redis:
- **In-Memory Speed**: Redis caches DNS results in memory, offering near-instant retrieval.
- **Improved Throughput**: Offloads repetitive DNS requests from upstream servers.
- **Reduced Load**: Minimizes the number of external DNS queries.
- **Reliable Caching**: Maintains fast access even under heavy load.

---

## 🛠️ Usage

> This container is tailored for **Unraid**.  
> Make sure to assign a **dedicated IP** or use a **custom Docker network**, as port `53` is typically occupied by Docker/Unraid by default.

### ⚙️ Default Settings:
- **AdGuard Home Web UI**: `http://<your-ip>:3000`
- **Default credentials**: `admin` / `admin`
- Configuration files are located at:  
  `/mnt/user/appdata/adguard-unbound-redis/`

| Directory       | Description                         |
|----------------|-------------------------------------|
| `/redis`        | Redis configuration files           |
| `/AdGuardHome`  | AdGuard Home config (`AdGuardHome.yaml`) |
| `/unbound`      | Unbound configuration files         |
| `/data`         | Working directory for AdGuard Home  |
| `/userfilters` | **Your own custom filter files (.txt, .list, etc.)** |

---

## 🌐 DNS Configuration

By default, Unbound is set to forward all DNS requests to **public resolvers**.  
Currently, **Cloudflare DNS** is used.

- You can modify this behavior in the `forward-queries.conf` file.
- Other DNS providers are pre-defined and can be customized or added.
- To enable **full recursive resolution**, simply **delete** the `forward-queries.conf` file.

---

### 📂 Custom User Filters

You can now add your own filter blocklist files to the container by placing them in the `/config/userfilters/` folder.

**Important:**  
To enable AdGuard Home to read your custom filter files, you must ensure that your configuration file (`AdGuardHome.yaml`) contains:

```
safe_fs_patterns:
   - /config/userfilters/*
```

You have two options:

- **Option 1: Manual update**  
  Edit `AdGuardHome.yaml` (found in `/mnt/user/appdata/adguard-unbound-redis/AdGuardHome/AdGuardHome.yaml`) and add or update the `safe_fs_patterns` section as shown above. Then restart the container.

- **Option 2: Auto-generate fresh config**  
  Delete (or move) your existing `AdGuardHome.yaml` config file and restart the container.  
  The container will create a new config file with the correct `safe_fs_patterns` entry by default.  
  _**Warning:** This resets all your AdGuard Home settings!_

**Afterwards:**  
Add your local blocklist(s) in AdGuard Home’s web UI (Filters → DNS blocklists) by specifying the file path, for example: `/config/userfilters/myblocklist.txt`.

---

## 🚫 Blocklists Enabled by Default

- [AdGuard DNS Filter](https://github.com/AdguardTeam/AdguardSDNSFilter)
- [HaGeZi's Threat Intelligence Feeds](https://github.com/hagezi/dns-blocklists?tab=readme-ov-file#tif)
- [HaGeZi's Multi PRO Blocklist](https://github.com/hagezi/dns-blocklists?tab=readme-ov-file#pro)

---

Enjoy faster, smarter, and more private DNS with this all-in-one Docker solution! 🛡️⚡
