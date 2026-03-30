# iamjavadali/nextcloudpi

A Nextcloud stack designed for Docker Compose, targeting **Raspberry Pi 5 (ARM64/aarch64)** — but also works on x86_64.

Services:
- **Nextcloud FPM** (this image: `iamjavadali/nextcloudpi`)
- **Nginx** (FastCGI web front-end)
- **MariaDB** (database)
- **Redis** (cache/locking)
- **Cron** (background jobs)

The container is based on `nextcloud:fpm` and adds:
- `ffmpeg` + `ghostscript` for media previews
- `imagick` recompiled natively for ARM64 (the upstream image ships an x86_64 binary that SIGSEGVs on aarch64)
- OPcache JIT disabled (PHP 8.x JIT is unstable on ARM64)

---

## Quick Start

### 1) Clone this repo or copy the files

```bash
cd ~
git clone https://github.com/iamjavadali/nextcloudpi.git nextcloud
cd nextcloud/nextcloud
```

### 2) Create your `.env`

```bash
cp .env.example .env
nano .env   # fill in passwords and domain
```

### 3) Start the stack

```bash
docker compose up -d
```

### 4) Open Nextcloud

- Local/LAN access: `http://<server-ip>:8080`
- If reverse proxied (recommended): `https://yourdomain.com`

Login using the admin credentials you set in `.env`.

---

## Files

### `.env.example` → copy to `.env`

**Important:** keep comments on their own lines. Do **not** put comments after values.

```dotenv
# ---- DATABASE ----
# Change these 4 values
MYSQL_ROOT_PASSWORD=CHANGE_ME_ROOT
MYSQL_PASSWORD=CHANGE_ME_DBUSER
MYSQL_DATABASE=nextclouddb
MYSQL_USER=admin

# Hostname matches the service name in docker-compose.yml
MYSQL_HOST=db

# ---- REDIS ----
REDIS_HOST=redis

# ---- PHP / Nextcloud Runtime Settings ----
PHP_MEMORY_LIMIT=2G
PHP_UPLOAD_LIMIT=10G
PHP_POST_MAX_SIZE=10G
PHP_MAX_EXECUTION_TIME=3600
PHP_MAX_INPUT_TIME=3600
OPCACHE_MEM_SIZE=128
OPCACHE_MAX_ACCELERATED_FILES=10000
OPCACHE_INTERNED_STRINGS_BUFFER=16
OPCACHE_REVALIDATE_FREQ=1

# ---- DOMAIN / OVERWRITE NEXTCLOUD ----
# Set to your domain (with https://) or local IP (e.g. http://192.168.1.115:8080)
OVERWRITECLIURL=https://yourdomain.com
OVERWRITEPROTOCOL=https

# Space-separated list — add your domain and/or host machine IP
# Example: yourdomain.com localhost 192.168.1.115
NEXTCLOUD_TRUSTED_DOMAINS=yourdomain.com localhost nextcloud-app

# Reverse proxy IP ranges — RFC1918 private ranges cover most setups
TRUSTED_PROXIES_NEXTCLOUD=127.0.0.0/8 10.0.0.0/8 172.16.0.0/12 192.168.0.0/16

# ---- EMAIL / SMTP ----
SMTP_MODE=smtp
SMTP_SECURE=ssl
SMTP_PORT=465
MAIL_FROM_ADDRESS=user
MAIL_DOMAIN=yourdomain.com
SMTP_HOST=mail.yourdomain.com
SMTP_NAME=user@yourdomain.com
SMTP_PASSWORD=CHANGE_ME_SMTP

# ---- NEXTCLOUD ADMIN DASHBOARD ----
NEXTCLOUD_ADMIN_USER=admin
NEXTCLOUD_ADMIN_PASSWORD=CHANGE_ME_ADMIN
```

---

### `docker-compose.yml`

Uses **bind mounts** (`./app`, `./db`) instead of named volumes so data is visible on the host and easy to back up.

> **OVERWRITEPROTOCOL** is commented out so this image works without a reverse proxy (HTTP).
> Uncomment it if you're running behind nginx-proxy-manager or any HTTPS proxy.

```yaml
networks:
  nextcloud:

services:

  # --- MariaDB Database ---
  db:
    container_name: nextcloud-db
    image: mariadb:11.8
    restart: always
    command: >
      --transaction-isolation=READ-COMMITTED
      --log-bin=binlog
      --binlog-format=ROW
      --log_bin_trust_function_creators=1
      --max_allowed_packet=256M
      --wait_timeout=28800
      --net_read_timeout=120
      --net_write_timeout=300
    volumes:
      - ./db:/var/lib/mysql
    networks:
      - nextcloud
    environment:
      - MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}
      - MYSQL_PASSWORD=${MYSQL_PASSWORD}
      - MYSQL_DATABASE=${MYSQL_DATABASE}
      - MYSQL_USER=${MYSQL_USER}
    healthcheck:
      test: ["CMD", "healthcheck.sh", "--connect", "--innodb_initialized"]
      start_period: 30s
      interval: 10s
      timeout: 5s
      retries: 5

  # --- Redis Cache ---
  redis:
    container_name: nextcloud-redis
    image: redis:alpine
    restart: always
    networks:
      - nextcloud

  # --- Nextcloud App (PHP-FPM) ---
  app:
    container_name: nextcloud-app
    build:
      context: .
      dockerfile: Dockerfile
    image: iamjavadali/nextcloudpi
    restart: always
    networks:
      - nextcloud
    depends_on:
      db:
        condition: service_healthy
      redis:
        condition: service_started
    volumes:
      - ./app:/var/www/html
    environment:
      - MYSQL_DATABASE=${MYSQL_DATABASE}
      - MYSQL_USER=${MYSQL_USER}
      - MYSQL_PASSWORD=${MYSQL_PASSWORD}
      - MYSQL_HOST=${MYSQL_HOST}
      - REDIS_HOST=${REDIS_HOST}
      - NEXTCLOUD_ADMIN_USER=${NEXTCLOUD_ADMIN_USER}
      - NEXTCLOUD_ADMIN_PASSWORD=${NEXTCLOUD_ADMIN_PASSWORD}
      - NEXTCLOUD_TRUSTED_DOMAINS=${NEXTCLOUD_TRUSTED_DOMAINS}
      - TRUSTED_PROXIES_NEXTCLOUD=${TRUSTED_PROXIES_NEXTCLOUD}
      - OVERWRITECLIURL=${OVERWRITECLIURL}
      # - OVERWRITEPROTOCOL=${OVERWRITEPROTOCOL}
      - PHP_MEMORY_LIMIT=${PHP_MEMORY_LIMIT}
      - PHP_UPLOAD_LIMIT=${PHP_UPLOAD_LIMIT}
      - PHP_POST_MAX_SIZE=${PHP_POST_MAX_SIZE}
      - PHP_MAX_EXECUTION_TIME=${PHP_MAX_EXECUTION_TIME}
      - PHP_MAX_INPUT_TIME=${PHP_MAX_INPUT_TIME}
      - OPCACHE_MEM_SIZE=${OPCACHE_MEM_SIZE}
      - OPCACHE_MAX_ACCELERATED_FILES=${OPCACHE_MAX_ACCELERATED_FILES}
      - OPCACHE_INTERNED_STRINGS_BUFFER=${OPCACHE_INTERNED_STRINGS_BUFFER}
      - OPCACHE_REVALIDATE_FREQ=${OPCACHE_REVALIDATE_FREQ}
      - SMTP_MODE=${SMTP_MODE}
      - SMTP_SECURE=${SMTP_SECURE}
      - SMTP_PORT=${SMTP_PORT}
      - MAIL_FROM_ADDRESS=${MAIL_FROM_ADDRESS}
      - MAIL_DOMAIN=${MAIL_DOMAIN}
      - SMTP_HOST=${SMTP_HOST}
      - SMTP_NAME=${SMTP_NAME}
      - SMTP_PASSWORD=${SMTP_PASSWORD}

  # --- Background Cron Jobs ---
  cron:
    container_name: nextcloud-cron
    build:
      context: .
      dockerfile: Dockerfile
    restart: always
    entrypoint: /cron.sh
    depends_on:
      - app
    networks:
      - nextcloud
    volumes:
      - ./app:/var/www/html
    environment:
      - OVERWRITECLIURL=${OVERWRITECLIURL}
      # - OVERWRITEPROTOCOL=${OVERWRITEPROTOCOL}
      - NEXTCLOUD_TRUSTED_DOMAINS=${NEXTCLOUD_TRUSTED_DOMAINS}
      - TRUSTED_PROXIES_NEXTCLOUD=${TRUSTED_PROXIES_NEXTCLOUD}
      - PHP_MEMORY_LIMIT=${PHP_MEMORY_LIMIT}
      - PHP_UPLOAD_LIMIT=${PHP_UPLOAD_LIMIT}
      - PHP_POST_MAX_SIZE=${PHP_POST_MAX_SIZE}
      - PHP_MAX_EXECUTION_TIME=${PHP_MAX_EXECUTION_TIME}
      - PHP_MAX_INPUT_TIME=${PHP_MAX_INPUT_TIME}
      - OPCACHE_MEM_SIZE=${OPCACHE_MEM_SIZE}
      - OPCACHE_MAX_ACCELERATED_FILES=${OPCACHE_MAX_ACCELERATED_FILES}
      - OPCACHE_INTERNED_STRINGS_BUFFER=${OPCACHE_INTERNED_STRINGS_BUFFER}
      - OPCACHE_REVALIDATE_FREQ=${OPCACHE_REVALIDATE_FREQ}

  # --- Nginx Web (FastCGI bridge) ---
  web:
    container_name: nextcloud-web
    image: nginx:stable-alpine
    restart: always
    depends_on:
      - app
    networks:
      - nextcloud
    ports:
      - "8080:80"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
      - ./app:/var/www/html
```

---

### `nginx.conf`

Full `nginx.conf` (not a `conf.d` snippet) mounted as `/etc/nginx/nginx.conf`. Includes Docker DNS resolver, gzip, security headers, correct FastCGI parameters for Nextcloud, and static asset caching.

> HSTS is **not** set here — it belongs in your reverse proxy (nginx-proxy-manager toggle).

```nginx
worker_processes auto;

error_log  /var/log/nginx/error.log warn;
pid        /var/run/nginx.pid;

events {
    worker_connections 1024;
}

http {
    include      mime.types;
    default_type application/octet-stream;

    types {
        text/javascript mjs;
    }

    sendfile        on;
    keepalive_timeout 65;
    server_tokens off;

    # Docker internal DNS
    resolver 127.0.0.11 valid=30s;

    map $arg_v $asset_immutable {
        ""      "";
        default ", immutable";
    }

    upstream php-handler {
        server app:9000;
    }

    gzip on;
    gzip_vary on;
    gzip_comp_level 4;
    gzip_min_length 256;
    gzip_proxied expired no-cache no-store private no_last_modified no_etag auth;
    gzip_types
        application/atom+xml text/javascript application/javascript
        application/json application/ld+json application/manifest+json
        application/rss+xml application/wasm application/xhtml+xml
        application/xml font/opentype image/bmp image/svg+xml image/x-icon
        text/cache-manifest text/css text/plain text/vcard text/vtt
        text/x-component text/x-cross-domain-policy;

    server {
        listen 80;

        client_max_body_size 10G;
        client_body_timeout 300s;
        client_body_buffer_size 512k;
        fastcgi_buffers 64 4K;

        add_header Referrer-Policy                   "no-referrer"       always;
        add_header X-Content-Type-Options            "nosniff"           always;
        add_header X-Frame-Options                   "SAMEORIGIN"        always;
        add_header X-Permitted-Cross-Domain-Policies "none"              always;
        add_header X-Robots-Tag                      "noindex, nofollow" always;

        fastcgi_hide_header X-Powered-By;

        root  /var/www/html;
        index index.php index.html /index.php$request_uri;

        location = / {
            if ($http_user_agent ~ ^DavClnt) {
                return 302 /remote.php/webdav/$is_args$args;
            }
        }

        location = /robots.txt {
            allow all;
            log_not_found off;
            access_log    off;
        }

        location ^~ /.well-known {
            location = /.well-known/carddav { return 301 /remote.php/dav/; }
            location = /.well-known/caldav  { return 301 /remote.php/dav/; }
            location /.well-known/acme-challenge  { try_files $uri $uri/ =404; }
            location /.well-known/pki-validation  { try_files $uri $uri/ =404; }
            return 301 /index.php$request_uri;
        }

        location ~ ^/(?:build|tests|config|lib|3rdparty|templates|data)(?:$|/) { return 404; }
        location ~ ^/(?:\.|autotest|occ|issue|indie|db_|console)               { return 404; }

        location ~ \.php(?:$|/) {
            rewrite ^/(?!index|remote|public|cron|core\/ajax\/update|status|ocs\/v[12]|updater\/.+|ocs-provider\/.+|.+\/richdocumentscode(_arm64)?\/proxy) /index.php$request_uri;

            fastcgi_split_path_info ^(.+?\.php)(/.*)$;
            set $path_info $fastcgi_path_info;
            try_files $fastcgi_script_name =404;

            include fastcgi_params;
            fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
            fastcgi_param PATH_INFO       $path_info;
            fastcgi_param HTTPS           on;
            fastcgi_param modHeadersAvailable true;
            fastcgi_param front_controller_active true;

            fastcgi_pass php-handler;
            fastcgi_intercept_errors    on;
            fastcgi_request_buffering   on;
            fastcgi_max_temp_file_size  0;
        }

        location ~ \.(?:css|js|mjs|svg|gif|ico|jpg|png|webp|wasm|tflite|map|ogg|flac|mp4|webm)$ {
            try_files $uri /index.php$request_uri;
            add_header Cache-Control "public, max-age=15778463$asset_immutable";
            add_header Referrer-Policy                   "no-referrer"       always;
            add_header X-Content-Type-Options            "nosniff"           always;
            add_header X-Frame-Options                   "SAMEORIGIN"        always;
            add_header X-Permitted-Cross-Domain-Policies "none"              always;
            add_header X-Robots-Tag                      "noindex, nofollow" always;
            access_log off;
        }

        location ~ \.(otf|woff2?)$ {
            try_files $uri /index.php$request_uri;
            expires    7d;
            access_log off;
        }

        location /remote {
            return 301 /remote.php$request_uri;
        }

        location / {
            try_files $uri $uri/ /index.php$request_uri;
        }
    }
}
```

---

## Post-first-launch setup (clears Security & Setup warnings)

After the stack is running and you've logged in for the first time, run these `occ` commands to configure settings that can't be set via environment variables.

### Server identity + locale

```bash
docker exec -u www-data nextcloud-app php occ config:system:set instanceid --value="your_unique_id"
docker exec -u www-data nextcloud-app php occ config:system:set default_phone_region --value="US"
docker exec -u www-data nextcloud-app php occ config:system:set maintenance_window_start --type=integer --value=1
```

### Enable preview generation (required for Memories app and thumbnails)

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

### WOPI allowlist (required if using Nextcloud Office behind Cloudflare)

Replace the IPs below with the Cloudflare IPv4 ranges (or wherever your Collabora/CODE server resolves from):

```bash
docker exec -u www-data nextcloud-app php occ config:app:set richdocuments wopi_allowlist \
  --value="103.21.244.0/22,103.22.200.0/22,103.31.4.0/22,104.16.0.0/13,104.24.0.0/14,108.162.192.0/18,131.0.72.0/22,141.101.64.0/18,162.158.0.0/15,172.64.0.0/13,173.245.48.0/20,188.114.96.0/20,190.93.240.0/20,197.234.240.0/22,198.41.128.0/17"
```

---

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

---

## Viewing logs

```bash
docker compose logs -f --tail=200
```

---

## Updating

```bash
docker compose pull
docker compose up -d
```

---

## ARM64 notes (Raspberry Pi 5)

The upstream `nextcloud:fpm` image ships the `imagick` PHP extension compiled for x86_64. On ARM64 (aarch64) this causes SIGSEGV worker crashes when processing images. This image fixes it by recompiling `imagick` via PECL during the Docker build.

PHP 8.x OPcache JIT is also unstable on ARM64 and causes additional SIGSEGV crashes. The Dockerfile disables it via `zzz-arm64-jit-disable.ini` (named with `zzz-` prefix so it loads after `opcache-recommended.ini`).

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
