# Nextcloud — Docker Stack

Nextcloud FPM running behind Nginx, with MariaDB, Redis, and a cron worker. Designed for **Raspberry Pi 5 (ARM64)**, but also usable on other Docker hosts.

This stack uses:

- `iamjavadali/nextcloudpi` for the PHP-FPM app container
- `nginx:stable-alpine` as the web front-end
- `mariadb:11.8`
- `redis:alpine`
- a separate `nextcloud-cron` container

The compose file uses:

- bind mounts for `./app` and `./db`
- port `8080:80` on the `web` container
- an internal `nextcloud` network
- an external `proxy` network for reverse proxy integration

---

## Architecture

### Direct access or reverse proxy flow

```text
Browser / Reverse Proxy
        │
        ▼
 nextcloud-web   (nginx:stable-alpine, port 80 inside container)
        │
        ▼
 nextcloud-app   (iamjavadali/nextcloudpi, PHP-FPM :9000)
        │
   ┌────┴────┐
   ▼         ▼
nextcloud-db  nextcloud-redis
(MariaDB 11.8) (redis:alpine)
```

`nextcloud-cron` shares the `app` bind mount and runs background jobs via `/cron.sh`.

---

## Files in this folder

- `docker-compose.yml` — full Nextcloud stack
- `.env.example` — starter environment variables
- `nginx.conf` — internal Nginx config for the `web` container
- `README.md` — this file

---

## Quick start

```bash
cp .env.example .env
nano .env
docker compose up -d
```

You do **not** need to create the `app` and `db` folders manually first. Docker Compose will create those bind-mounted host directories automatically on first startup.

Then open Nextcloud using one of these patterns, depending on your setup:

- Direct local/LAN access: `http://<host-ip>:8080`
- Reverse proxy / public domain: `https://cloud.yourdomain.com`

---

## Choose your setup

## Option 1: Direct local or LAN access, no reverse proxy

Use this when you want to open Nextcloud directly on your server IP and port `8080`.

Example:

```text
http://192.168.1.115:8080
```

### Recommended `.env` values

```dotenv
# ---- DOMAIN / OVERWRITE NEXTCLOUD ----
OVERWRITECLIURL=http://192.168.1.115:8080
OVERWRITEHOST=192.168.1.115:8080
OVERWRITEPROTOCOL=http

NEXTCLOUD_TRUSTED_DOMAINS=localhost 192.168.1.115 nextcloud-app

# Private proxy ranges cover most normal home/LAN setups
TRUSTED_PROXIES_NEXTCLOUD=127.0.0.0/8 10.0.0.0/8 172.16.0.0/12 192.168.0.0/16
```

### Notes

- `OVERWRITEPROTOCOL=http` is correct for direct non-TLS access.
- `OVERWRITEHOST` should match the exact hostname or IP and port used in the browser.
- `OVERWRITECLIURL` should match the full URL you want Nextcloud to generate for links and CLI jobs.
- Add every hostname or IP you use to `NEXTCLOUD_TRUSTED_DOMAINS`.

---

## Option 2: Reverse proxy or HTTPS setup

Use this when Nextcloud is behind something like:

- Nginx Proxy Manager
- Traefik
- Caddy
- Cloudflare Tunnel
- another reverse proxy or SSL terminator

Example public URL:

```text
https://cloud.yourdomain.com
```

### Recommended `.env` values

```dotenv
# ---- DOMAIN / OVERWRITE NEXTCLOUD ----
OVERWRITECLIURL=https://cloud.yourdomain.com
OVERWRITEHOST=cloud.yourdomain.com
OVERWRITEPROTOCOL=https

NEXTCLOUD_TRUSTED_DOMAINS=cloud.yourdomain.com nextcloud-app

TRUSTED_PROXIES_NEXTCLOUD=127.0.0.0/8 10.0.0.0/8 172.16.0.0/12 192.168.0.0/16
```

### Notes

- `OVERWRITEPROTOCOL=https` is required when users access Nextcloud over HTTPS.
- `OVERWRITEHOST` should be the public hostname only, without `https://`.
- `OVERWRITECLIURL` should be the full public URL.
- The `web` container is attached to the external `proxy` network specifically for reverse-proxy integration.

---

## Configuration (`.env`)

Copy `.env.example` to `.env` and update these values at minimum.

| Variable | Description |
|---|---|
| `MYSQL_ROOT_PASSWORD` | MariaDB root password |
| `MYSQL_PASSWORD` | MariaDB app user password |
| `MYSQL_DATABASE` | MariaDB database name |
| `MYSQL_USER` | MariaDB app user |
| `MYSQL_HOST` | Database service hostname, default `db` |
| `REDIS_HOST` | Redis service hostname, default `redis` |
| `NEXTCLOUD_ADMIN_USER` | Initial admin username |
| `NEXTCLOUD_ADMIN_PASSWORD` | Initial admin password |
| `OVERWRITECLIURL` | Full browser/CLI URL |
| `OVERWRITEHOST` | Hostname or IP:port used by browser logins |
| `OVERWRITEPROTOCOL` | `http` for direct local use, `https` behind TLS proxy |
| `NEXTCLOUD_TRUSTED_DOMAINS` | Space-separated allowed hostnames/IPs |
| `TRUSTED_PROXIES_NEXTCLOUD` | Proxy IP ranges |
| SMTP variables | Mail server settings for notifications and password resets |

### Important starter sections from `.env.example`

```dotenv
# ---- DATABASE ----
MYSQL_ROOT_PASSWORD=CHANGE_ME_ROOT
MYSQL_PASSWORD=CHANGE_ME_DBUSER
MYSQL_DATABASE=nextclouddb
MYSQL_USER=admin
MYSQL_HOST=db

# ---- REDIS ----
REDIS_HOST=redis

# ---- NEXTCLOUD ADMIN DASHBOARD ----
NEXTCLOUD_ADMIN_USER=admin
NEXTCLOUD_ADMIN_PASSWORD=Change_Me_Admin123$
```

---

## Networking

- `nextcloud-web` is attached to both:
  - the internal `nextcloud` network
  - the external `proxy` network
- `db`, `redis`, and `cron` stay on the internal `nextcloud` network only
- `web` exposes `8080` on the host with `8080:80`

---

## Data directories

This stack uses **bind mounts** next to the compose file:

| Path | Contents |
|---|---|
| `./app/` | Nextcloud files, config, apps, and data |
| `./db/` | MariaDB data files |

Both directories are intended to stay outside git and should be backed up regularly.

### Example database backup

```bash
docker exec nextcloud-db sh -c \
  'mysqldump -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE"' > backup.sql
```

---

## Nginx behavior

The included `nginx.conf` is written as an **internal** web container config. It explicitly says no public `server_name` is needed because domain routing is expected to happen externally. It also sets `fastcgi_param HTTPS on`, which is useful for reverse-proxy-style deployments but worth remembering if you are troubleshooting direct local HTTP behavior.

---

## Post-first-launch setup

After the stack is running and you've logged in for the first time, continue with the full post-install guide here:

[`../INSTALL-and-SETUP.md`](../INSTALL-and-SETUP.md)

That guide covers:

- common Administration → Overview warnings
- preview providers
- mimetype repairs
- Talk signaling
- Collabora / WOPI allowlisting
- useful `occ` commands

### Minimum useful commands

```bash
docker exec nextcloud-app php occ config:system:set server_id \
  --value="nextcloud-pi5-primary"
docker exec -u www-data nextcloud-app php occ config:system:set default_phone_region --value="US"
docker exec -u www-data nextcloud-app php occ config:system:set maintenance_window_start --type=integer --value=1
docker exec -u www-data nextcloud-app php occ db:add-missing-indices
```

### Also useful after first launch

```bash
docker exec -u www-data nextcloud-app php occ maintenance:repair --include-expensive
docker exec -u www-data nextcloud-app php occ status
docker exec -u www-data nextcloud-app php occ config:list system --private
```

---

## Useful commands

### Logs

```bash
docker compose logs -f web app db
```

### OCC

```bash
docker exec -u www-data -it nextcloud-app php occ status
docker exec -u www-data -it nextcloud-app php occ app:list
docker exec -u www-data -it nextcloud-app php occ user:resetpassword admin
```

### Shell

```bash
docker exec -it nextcloud-app /bin/bash
```

### Update

```bash
docker compose pull
docker compose up -d
```

### Clean reset for test installs

```bash
docker compose down --volumes
rm -rf app db
docker compose up -d
```

---

## ARM64 notes (Raspberry Pi 5)

The upstream `nextcloud:fpm` image ships the `imagick` PHP extension compiled for x86_64. On ARM64 (`aarch64`) this causes SIGSEGV worker crashes when processing images. This image fixes it by recompiling `imagick` via PECL during the Docker build.

PHP 8.x OPcache JIT is also unstable on ARM64 and causes additional SIGSEGV crashes. The Dockerfile disables it via `zzz-arm64-jit-disable.ini`, named with the `zzz-` prefix so it loads after `opcache-recommended.ini`.

---

## Dockerfile (for transparency)

```dockerfile
# Use official Nextcloud FPM image (pulls linux/arm64 natively on Raspberry Pi 5)
FROM nextcloud:fpm

RUN set -ex; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        ffmpeg \
        ghostscript \
        libmagickwand-dev \
        libmagickcore-7.q16-10-extra \
    ; \
    rm -rf /var/lib/apt/lists/*; \
    pecl uninstall imagick; \
    pecl install imagick; \
    docker-php-ext-enable imagick

# Disable OPcache JIT — unstable on ARM64
RUN { \
        echo 'opcache.jit=disable'; \
        echo 'opcache.jit_buffer_size=0'; \
    } > /usr/local/etc/php/conf.d/zzz-arm64-jit-disable.ini
```

---

## Building locally

A `Dockerfile` is included if you want to build the image yourself instead of pulling from Docker Hub.

```bash
docker build -t iamjavadali/nextcloudpi:local .
```

Then update `docker-compose.yml` to use a local build instead of the published image.

Example approach:

```yaml
app:
  build:
    context: .
  image: iamjavadali/nextcloudpi:local
```

The current compose file uses `image: iamjavadali/nextcloudpi` for both `app` and `cron`.

---

## Summary

Use this folder if you want a Nextcloud stack with:

- Nextcloud FPM
- Nginx
- MariaDB
- Redis
- Cron
- ARM64-friendly image behavior
- direct local/LAN support
- reverse proxy / HTTPS support

For local use, set the `.env` for `http` and your IP:port.  
For reverse proxy use, set the `.env` for `https` and your public hostname.
