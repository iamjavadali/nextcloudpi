# iamjavadali/nextcloudpi

A Nextcloud stack designed for Docker Compose, using:
- **Nextcloud FPM** (this image: `iamjavadali/nextcloudpi`)
- **Nginx** (web front-end)
- **MariaDB** (database)
- **Redis** (cache/locking)
- **Cron** (background jobs)

This repo’s Nextcloud container is based on `nextcloud:fpm` and adds `ffmpeg` + `imagemagick` for richer previews.

---

## Quick Start

### 1) Create a folder and files
On your server (example on Raspberry Pi):

```bash
cd ~
mkdir -p nextcloud && cd nextcloud
touch docker-compose.yml nginx.conf .env
```

### 2) Copy/paste these files (below)
- Paste the **.env** into `./.env`
- Paste the **docker-compose.yml** into `./docker-compose.yml`
- Paste the **nginx.conf** into `./nginx.conf`

### 3) Start the stack
```bash
docker compose up -d
```

### 4) Open Nextcloud
- Local/LAN access: `http://<server-ip>:8080`
- If reverse proxied (recommended): `https://yourdomain.com`

Login using the admin credentials you set in `.env`.

---

## Files to Copy/Paste

### `.env` (save as `./.env`)
**Important:** keep comments on their own lines. Do **not** put comments after values (some setups treat that as part of the value).

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
# Change OVERWRITECLIURL to your domain or to your host IP Address without a port number. Example: https://192.168.1.115
OVERWRITECLIURL=https://yourdomain.com
OVERWRITEPROTOCOL=https

# Space-separated list - Change 'yourdomain.com' to your domain or to your host IP Address without a port number. Example: 192.168.1.115
NEXTCLOUD_TRUSTED_DOMAINS=yourdomain.com localhost nextcloud-app

# Add/adjust your reverse proxy IP ranges if needed
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
# Change your Nextcloud Admin user & password
NEXTCLOUD_ADMIN_USER=admin
NEXTCLOUD_ADMIN_PASSWORD=Changeme123$
```

---

### `docker-compose.yml` (save as `./docker-compose.yml`)
This version **pulls from Docker Hub** (recommended for most users).  
If you want to build locally instead, see the “Build locally” section further down.

OVERWRITEPROTOCOL=${OVERWRITEPROTOCOL} is hashed out in nextcloud-app and nextcloud-cron, so you can run this image without a reverse proxy. Unhash it if you are running behind a proxy.

```yaml
volumes:
  db:
  app:

networks:
  nextcloud:

services:
 # MySQL Database Server 
  db:
    container_name: nextcloud-db
    image: mariadb:10.6
    restart: always
    command: --transaction-isolation=READ-COMMITTED --log-bin=binlog --binlog-format=ROW --log_bin_trust_function_creators=1 --max_allowed_packet=256M --wait_timeout=28800 --net_read_timeout=120 --net_write_timeout=300
    volumes:
      - db:/var/lib/mysql
    networks:
      - nextcloud
    environment:
      - MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}
      - MYSQL_PASSWORD=${MYSQL_PASSWORD}
      - MYSQL_DATABASE=${MYSQL_DATABASE}
      - MYSQL_USER=${MYSQL_USER}

 # Regis Cache Server
  redis:
    container_name: nextcloud-redis
    image: redis:alpine
    restart: always
    networks:
      - nextcloud

 # Nextcloud App
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
      - db
      - redis
    volumes:
      - app:/var/www/html
    environment:
    # --- Database connection ---
      - MYSQL_DATABASE=${MYSQL_DATABASE}
      - MYSQL_USER=${MYSQL_USER}
      - MYSQL_PASSWORD=${MYSQL_PASSWORD}
      - MYSQL_HOST=${MYSQL_HOST}

    # --- Redis caching ---
      - REDIS_HOST=${REDIS_HOST}

    # --- Nextcloud initial setup ---
      - NEXTCLOUD_ADMIN_USER=${NEXTCLOUD_ADMIN_USER}
      - NEXTCLOUD_ADMIN_PASSWORD=${NEXTCLOUD_ADMIN_PASSWORD}

    # --- Trusted domains and proxy ---
      - NEXTCLOUD_TRUSTED_DOMAINS=${NEXTCLOUD_TRUSTED_DOMAINS}
      - TRUSTED_PROXIES_NEXTCLOUD=${TRUSTED_PROXIES_NEXTCLOUD}
      - OVERWRITECLIURL=${OVERWRITECLIURL}
    # - OVERWRITEPROTOCOL=${OVERWRITEPROTOCOL}

    # --- PHP / Runtime settings ---
      - PHP_MEMORY_LIMIT=${PHP_MEMORY_LIMIT}
      - PHP_UPLOAD_LIMIT=${PHP_UPLOAD_LIMIT}
      - PHP_POST_MAX_SIZE=${PHP_POST_MAX_SIZE}
      - PHP_MAX_EXECUTION_TIME=${PHP_MAX_EXECUTION_TIME}
      - PHP_MAX_INPUT_TIME=${PHP_MAX_INPUT_TIME}

    # --- OPCache settings (improve performance) ---
      - OPCACHE_MEM_SIZE=${OPCACHE_MEM_SIZE}
      - OPCACHE_MAX_ACCELERATED_FILES=${OPCACHE_MAX_ACCELERATED_FILES}
      - OPCACHE_INTERNED_STRINGS_BUFFER=${OPCACHE_INTERNED_STRINGS_BUFFER}
      - OPCACHE_REVALIDATE_FREQ=${OPCACHE_REVALIDATE_FREQ}

    # --- Email / SMTP settings ---
      - SMTP_MODE=${SMTP_MODE}
      - SMTP_SECURE=${SMTP_SECURE}
      - SMTP_PORT=${SMTP_PORT}
      - MAIL_FROM_ADDRESS=${MAIL_FROM_ADDRESS}
      - MAIL_DOMAIN=${MAIL_DOMAIN}
      - SMTP_HOST=${SMTP_HOST}
      - SMTP_NAME=${SMTP_NAME}
      - SMTP_PASSWORD=${SMTP_PASSWORD}

 # Background Task Cron jobs
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
      - app:/var/www/html
    environment:
      - OVERWRITECLIURL=${OVERWRITECLIURL}
   #  - OVERWRITEPROTOCOL=${OVERWRITEPROTOCOL}
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

# NGINX Web for Nextcloud
  web:
    container_name: nextcloud-web
    image: nginx:stable-alpine
    restart: always
    depends_on:
      - app
    networks:
      - nextcloud
    ports:
      - "8080:80" # Internal access, reverse proxied externally
    volumes:
      - ./nginx.conf:/etc/nginx/conf.d/default.conf:ro
      - app:/var/www/html
```

---

### `nginx.conf` (save as `./nginx.conf`)
**Note:** update your domain in 'server_name'.

```nginx
add_header X-Frame-Options "SAMEORIGIN";
add_header X-Content-Type-Options "nosniff";
add_header Referrer-Policy "no-referrer-when-downgrade";
add_header X-XSS-Protection "1; mode=block";
add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload" always;

server {
    listen 80;
    server_name localhost; # update your domain here

    root /var/www/html;
    index index.php index.html;

    client_max_body_size 10G;
    server_tokens off;

    # Redirect well-known URLs
    location = /.well-known/carddav { return 301 /remote.php/dav; }
    location = /.well-known/caldav { return 301 /remote.php/dav; }
    location ~ ^/.well-known/(?!acme-challenge|pki-validation) {
        return 301 /index.php$request_uri;
    }

    # OCS and ocm provider
    location ^~ /ocs-provider/ {
        root /var/www/html/;
        index index.php;
        try_files $uri $uri/ /ocs-provider/index.php?$args;
    }

    # JavaScript MIME fix for .mjs files
    location ~* \.mjs$ {
        default_type application/javascript;
        try_files $uri =404;
    }

    # Main handler
    location / {
        try_files $uri $uri/ /index.php$request_uri;
    }

    # PHP handler (FPM)
    location ~ \.php(?:$|/) {
        include fastcgi_params;
        fastcgi_split_path_info ^(.+\.php)(/.*)$;
        fastcgi_pass nextcloud-app:9000;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param PATH_INFO $fastcgi_path_info;
        fastcgi_index index.php;
        fastcgi_intercept_errors on;
        fastcgi_request_buffering off;
    }

    # Static files
    location ~* \.(?:css|js|woff2?|svg|gif|png|jpg|jpeg|ico|ttf|otf|eot|mjs)$ {
        try_files $uri /index.php$request_uri;
        access_log off;
        expires 6M;
        add_header Cache-Control "public";
    }

    # Deny access to sensitive files
    location ~ ^/(?:\.|autotest|occ|issue|indie|db_|console) {
        deny all;
    }

    location ~ ^/(?:build|tests|config|lib|3rdparty|templates|data)/ {
        deny all;
    }
}
```

---

## Post-install setup (clears common Security & setup warnings)

### Wait a few minutes
If you see a background job warning right after install, wait ~5 minutes for the cron container to run at least once.

### Fix: maintenance window + default phone region + enable previews
This edits `config.php` inside the Nextcloud volume.

1) Find where your Nextcloud volume lives:
```bash
docker inspect nextcloud-app --format '{{ range .Mounts }}{{ .Source }} -> {{ .Destination }}{{ "\n" }}{{ end }}'
```

2) Open `config.php` (path will look like `.../config/config.php`):
```bash
sudo -i
# Example path (yours may differ):
nano /var/lib/docker/volumes/nextcloud_app/_data/config/config.php
```

3) Add this **before** the final `);`
```php
  'default_phone_region' => 'US', // Change this to your region
  'maintenance_window_start' => 1,
  'enable_previews' => true,
  'enabledPreviewProviders' =>
  array (
    0 => 'OC\\Preview\\Movie',
    1 => 'OC\\Preview\\PNG',
    2 => 'OC\\Preview\\JPEG',
    3 => 'OC\\Preview\\GIF',
    4 => 'OC\\Preview\\BMP',
    5 => 'OC\\Preview\\XBitmap',
    6 => 'OC\\Preview\\MP3',
    7 => 'OC\\Preview\\MP4',
    8 => 'OC\\Preview\\TXT',
    9 => 'OC\\Preview\\MarkDown',
    10 => 'OC\\Preview\\PDF',
  ),
```

Save: `CTRL+X` then `y` then Enter.

---

## Commands to fix common warnings

### Fix: “One or more mimetype migrations are available”
```bash
docker exec -u www-data -it nextcloud-app php occ maintenance:repair --include-expensive
```

### Fix: “Database missing indices”
```bash
docker exec -u www-data -it nextcloud-app php occ db:add-missing-indices
```

---

## Extra useful commands (cheat sheet)

### Get a shell
```bash
docker exec -it nextcloud-app /bin/bash
# or (Alpine-style shells in some images)
docker exec -it nextcloud-app sh
```

### OCC basics
```bash
docker exec -u www-data -it nextcloud-app php occ
docker exec -u www-data -it nextcloud-app php occ status
```

### Re-scan files / cleanup
```bash
docker exec -u www-data -it nextcloud-app php occ files:scan --all
docker exec -u www-data -it nextcloud-app php occ files:cleanup
```

### “Memories” app commands (if you use it)
```bash
docker exec -u www-data -it nextcloud-app php occ memories:places-setup
docker exec -u www-data -it nextcloud-app php occ memories:index
docker exec -u www-data -it nextcloud-app php occ memories:index --force
docker exec -u www-data -it nextcloud-app php occ memories:index --clear
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

## Build locally (optional)

If you want to build the image on your machine instead of pulling from Docker Hub:

```bash
docker build -t iamjavadali/nextcloudpi:local .
```

Then edit `docker-compose.yml` and change:
- `iamjavadali/nextcloudpi:latest` to `iamjavadali/nextcloudpi:local`

---

## Included Dockerfile (for transparency)

```dockerfile
# Use latest official Nextcloud FPM image
FROM nextcloud:fpm

# Install required tools
RUN apt update && \
    apt install -y ffmpeg imagemagick && \
    apt clean && rm -rf /var/lib/apt/lists/*
```
