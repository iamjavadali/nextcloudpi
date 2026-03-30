# iamjavadali/nextcloudpi

A Docker Compose Nextcloud stack built for Raspberry Pi 5 (ARM64 / aarch64), and also usable on x86_64.

This branch is designed around a complete self-hosted Nextcloud stack using:

- Nextcloud FPM (`iamjavadali/nextcloudpi`)
- Nginx as the FastCGI web front-end
- MariaDB
- Redis
- Cron

The custom image is based on `nextcloud:fpm` and adds:

- `ffmpeg` and `ghostscript` for previews
- `imagick` rebuilt natively for ARM64
- OPcache JIT disabled for better ARM64 stability

---

## What this branch includes

### `nextcloud/Dockerfile`
Builds the custom Nextcloud image used in this stack.

### `nextcloud/docker-compose.yml`
Runs the full stack:

- `db`
- `redis`
- `app`
- `cron`
- `web`

It uses bind mounts instead of named volumes:

- `./app:/var/www/html`
- `./db:/var/lib/mysql`

That makes it easier to inspect, back up, and migrate your data from the host.

### `nextcloud/.env.example`
Starter environment file for local testing, LAN access, or reverse-proxy deployments.

This branch now supports all three overwrite settings:

- `OVERWRITECLIURL`
- `OVERWRITEHOST`
- `OVERWRITEPROTOCOL`

These are important for login/session handling and for generating the correct URLs in both local and reverse-proxy setups.

### `nextcloud/nginx.conf`
Full Nginx config for the internal web container.

### `Jenkins/Jenkinsfile`
Pipeline used to build, test, validate login, and push the Docker image to Docker Hub.

---

## Folder layout

```bash
.
├── Jenkins/
│   └── Jenkinsfile
├── nextcloud/
│   ├── .env.example
│   ├── Dockerfile
│   ├── docker-compose.yml
│   └── nginx.conf
└── README.md
```

---

## Quick start

### 1) Clone the repo

```bash
cd ~
git clone https://github.com/iamjavadali/nextcloudpi.git nextcloud
cd nextcloud/nextcloud
```

### 2) Create your environment file

```bash
cp .env.example .env
nano .env
```

### 3) Start the stack

```bash
docker compose up -d
```

### 4) Open Nextcloud

- Direct local/LAN setup: `http://<server-ip>:8080`
- Reverse proxy / HTTPS setup: `https://yourdomain.com`

Log in using the admin username and password from your `.env`.

---

## Choose your setup

## Option 1: Direct local or LAN access, no reverse proxy

Use this when you are opening Nextcloud directly on your server IP and port `8080`, for example:

```text
http://192.168.1.115:8080
```

### Recommended `.env` values

```dotenv
# ---- DOMAIN / OVERWRITE NEXTCLOUD ----
OVERWRITECLIURL=http://localhost:8080
OVERWRITEHOST=localhost:8080
OVERWRITEPROTOCOL=http

# Add your LAN IP if you will access from another device
NEXTCLOUD_TRUSTED_DOMAINS=localhost 192.168.1.115 nextcloud-app

# Keep private ranges unless you know you need something else
TRUSTED_PROXIES_NEXTCLOUD=127.0.0.0/8 10.0.0.0/8 172.16.0.0/12 192.168.0.0/16
```

### Notes

- `OVERWRITEPROTOCOL=http` is correct for a direct non-TLS local setup.
- `OVERWRITEHOST` should match how you access it in the browser.
- If you are using a LAN IP instead of `localhost`, update both:
  - `OVERWRITECLIURL`
  - `OVERWRITEHOST`

Example:

```dotenv
OVERWRITECLIURL=http://192.168.1.115:8080
OVERWRITEHOST=192.168.1.115:8080
OVERWRITEPROTOCOL=http
NEXTCLOUD_TRUSTED_DOMAINS=localhost 192.168.1.115 nextcloud-app
```

---

## Option 2: Reverse proxy or HTTPS setup

Use this when Nextcloud is behind:

- Nginx Proxy Manager
- Traefik
- Caddy
- Cloudflare Tunnel
- another reverse proxy or SSL terminator

and users access it through a domain like:

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

# Keep private ranges unless your proxy network requires something more specific
TRUSTED_PROXIES_NEXTCLOUD=127.0.0.0/8 10.0.0.0/8 172.16.0.0/12 192.168.0.0/16
```

### Notes

- `OVERWRITEPROTOCOL=https` is required when users access Nextcloud through HTTPS.
- `OVERWRITEHOST` should be your public hostname, without `https://`.
- `OVERWRITECLIURL` should be the full public URL.
- Your reverse proxy should handle TLS and forward traffic to this stack on port `8080`.

---

## Required `.env` sections

## Database

```dotenv
MYSQL_ROOT_PASSWORD=CHANGE_ME_ROOT
MYSQL_PASSWORD=CHANGE_ME_DBUSER
MYSQL_DATABASE=nextclouddb
MYSQL_USER=admin
MYSQL_HOST=db
```

## Redis

```dotenv
REDIS_HOST=redis
```

## PHP / runtime

```dotenv
PHP_MEMORY_LIMIT=2G
PHP_UPLOAD_LIMIT=10G
PHP_POST_MAX_SIZE=10G
PHP_MAX_EXECUTION_TIME=3600
PHP_MAX_INPUT_TIME=3600
OPCACHE_MEM_SIZE=128
OPCACHE_MAX_ACCELERATED_FILES=10000
OPCACHE_INTERNED_STRINGS_BUFFER=16
OPCACHE_REVALIDATE_FREQ=1
```

## Mail / SMTP

```dotenv
SMTP_MODE=smtp
SMTP_SECURE=ssl
SMTP_PORT=465
MAIL_FROM_ADDRESS=user
MAIL_DOMAIN=yourdomain.com
SMTP_HOST=mail.yourdomain.com
SMTP_NAME=user@yourdomain.com
SMTP_PASSWORD=CHANGE_ME_SMTP
```

## Nextcloud admin

```dotenv
NEXTCLOUD_ADMIN_USER=admin
NEXTCLOUD_ADMIN_PASSWORD=Change_Me_Admin123!
```

Use a strong password, but avoid weird shell-sensitive starter examples when you are first testing.

---

## Example startup workflow

```bash
cp .env.example .env
nano .env
docker compose up -d
docker compose ps
```

Then open either:

```text
http://<server-ip>:8080
```

or

```text
https://yourdomain.com
```

depending on your setup.

---

## Important behavior

### Overwrite settings matter
This branch uses:

- `OVERWRITECLIURL`
- `OVERWRITEHOST`
- `OVERWRITEPROTOCOL`

These settings help Nextcloud generate the correct URLs and avoid browser login/session issues when accessed by IP, LAN hostname, or through a reverse proxy.

### Trusted domains matter
Make sure every hostname or IP you use to access Nextcloud is included in:

```dotenv
NEXTCLOUD_TRUSTED_DOMAINS=...
```

### Bind mounts are used on purpose
This stack uses host-visible directories instead of named volumes:

- `./app`
- `./db`

That makes backup and migration easier, but it also means old data persists unless you remove those directories.

---

## Common commands

### Start
```bash
docker compose up -d
```

### Stop
```bash
docker compose down
```

### Stop and remove volumes
```bash
docker compose down --volumes
```

### View logs
```bash
docker compose logs -f
```

### View only app logs
```bash
docker compose logs -f app
```

### Reset Nextcloud admin password
```bash
docker compose exec -u www-data app php occ user:resetpassword admin
```

### Show current system config
```bash
docker compose exec -u www-data app php occ config:list system --private
```

---

## Troubleshooting

## Login page loads but login fails
Check these first:

- `OVERWRITECLIURL`
- `OVERWRITEHOST`
- `OVERWRITEPROTOCOL`
- `NEXTCLOUD_TRUSTED_DOMAINS`

If you are using a reverse proxy, confirm:

- public hostname is in `NEXTCLOUD_TRUSTED_DOMAINS`
- `OVERWRITEPROTOCOL=https`
- `OVERWRITEHOST=yourdomain.com`
- `OVERWRITECLIURL=https://yourdomain.com`

If you are using direct local/LAN access, confirm:

- `OVERWRITEPROTOCOL=http`
- `OVERWRITEHOST=<server-ip>:8080`
- `OVERWRITECLIURL=http://<server-ip>:8080`

## Need a clean reset
If this is only a test install and you want to start over:

```bash
docker compose down --volumes
rm -rf app db
docker compose up -d
```

## Need to inspect live config
```bash
docker compose exec -u www-data app php occ config:list system --private
```

---

## Post-first-launch setup (clears Security & Setup warnings)

After the stack is running and you've logged in for the first time, run these `occ` commands to configure settings that can't be set via environment variables.

## Server identity + locale

```bash
docker exec -u www-data nextcloud-app php occ config:system:set instanceid --value="your_unique_id"
docker exec -u www-data nextcloud-app php occ config:system:set default_phone_region --value="US"
docker exec -u www-data nextcloud-app php occ config:system:set maintenance_window_start --type=integer --value=1
```

## Enable preview generation (required for Memories app and thumbnails)

```bash
docker exec -u www-data nextcloud-app php occ config:system:set enable_previews --type=boolean --value=true
docker exec -u www-data nextcloud-app php occ config:system:set enabledPreviewProviders 0 --value="OC\\Preview\\Movie"
docker exec -u www-data nextcloud-app php occ config:system:set enabledPreviewProviders 1 --value="OC\\Preview\\PNG"
docker exec -u www-data nextcloud-app php occ config:system:set enabledPreviewProviders 2 --value="OC\\Preview\\JPEG"
docker exec -u www-data nextcloud-app php occ config:system:set enabledPreviewProviders 3 --value="OC\\Preview\\GIF"
docker exec -u www-data nextcloud-app php occ config:system:set enabledPreviewProviders 4 --value="OC\\Preview\\BMP"
docker exec -u www-data nextcloud-app php occ config:system:set enabledPreviewProviders 5 --value="OC\\Preview\\XBitmap"
docker exec -u www-data nextcloud-app php occ config:system:set enabledPreviewProviders 6 --value="OC\\Preview\\MP3"
docker exec -u www-data nextcloud-app php occ config:system:set enabledPreviewProviders 7 --value="OC\\Preview\\MP4"
docker exec -u www-data nextcloud-app php occ config:system:set enabledPreviewProviders 8 --value="OC\\Preview\\TXT"
docker exec -u www-data nextcloud-app php occ config:system:set enabledPreviewProviders 9 --value="OC\\Preview\\MarkDown"
docker exec -u www-data nextcloud-app php occ config:system:set enabledPreviewProviders 10 --value="OC\\Preview\\PDF"
```

## WOPI allowlist (required if using Nextcloud Office behind Cloudflare)

Replace the IPs below with the Cloudflare IPv4 ranges, or wherever your Collabora / CODE server resolves from:

```bash
docker exec -u www-data nextcloud-app php occ config:app:set richdocuments wopi_allowlist \
  --value="103.21.244.0/22,103.22.200.0/22,103.31.4.0/22,104.16.0.0/13,104.24.0.0/14,108.162.192.0/18,131.0.72.0/22,141.101.64.0/18,162.158.0.0/15,172.64.0.0/13,173.245.48.0/20,188.114.96.0/20,190.93.240.0/20,197.234.240.0/22,198.41.128.0/17"
```

## Common maintenance commands

### Fix warnings

```bash
# "One or more mimetype migrations are available"
docker exec -u www-data -it nextcloud-app php occ maintenance:repair --include-expensive

# "Database missing indices"
docker exec -u www-data -it nextcloud-app php occ db:add-missing-indices
```

### OCC basics

```bash
docker exec -u www-data -it nextcloud-app php occ status
docker exec -u www-data -it nextcloud-app php occ files:scan --all
docker exec -u www-data -it nextcloud-app php occ files:cleanup
```

### Memories app

```bash
docker exec -u www-data -it nextcloud-app php occ memories:places-setup
docker exec -u www-data -it nextcloud-app php occ memories:index
```

### Viewing logs

```bash
docker compose logs -f --tail=200
```

### Updating

```bash
docker compose pull
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

## Docker image

This stack uses:

```text
iamjavadali/nextcloudpi
```

If you are using the Jenkins pipeline in this branch, it builds, deploys, validates, and pushes that image to Docker Hub.

---

## Summary

Use this branch if you want a Nextcloud stack with:

- Docker Compose
- MariaDB
- Redis
- Cron
- Nginx
- ARM64-friendly image behavior
- direct local/LAN support
- reverse proxy / HTTPS support

For local use, configure the `.env` for `http` and your IP:port.  
For reverse proxy use, configure the `.env` for `https` and your public hostname.
