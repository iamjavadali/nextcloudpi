# NextcloudPI — Docker Stack

This repository provides a containerized Nextcloud setup using dedicated Nginx, Nextcloud FPM, MariaDB, Redis, and a separate cron worker. Configuration is driven by a single `.env` file created by renaming the provided `env.txt`.

> Repo files: `docker-compose.yml`, `Dockerfile`, `nginx.conf`, and `env.txt` (rename to `.env`).

---

## Architecture

- **web**: nginx:stable-alpine serving `/var/www/html` and proxying PHP to the app
- **app**: Nextcloud FPM built from `Dockerfile` (base `nextcloud:fpm`) with media/preview tools
- **db**: mariadb:10.6 storing application data
- **redis**: redis:alpine for file locking and caching
- **cron**: runs Nextcloud background jobs via `/cron.sh`

**Network**
- `nextcloud` internal network connecting all services

**Volumes**
- Top-level volumes: db, app

**Exposed port**
- `web` publishes **8080/tcp** on the host. Point your public reverse proxy to this port.

---

## Prerequisites

- Docker and Docker Compose plugin installed
- A reverse proxy or load balancer for public HTTPS
- DNS record(s) pointing to your proxy

---

## Quick start

1) **Clone and enter the repo**
```bash
git clone https://github.com/iamjavadali/nextcloudpi.git
cd nextcloudpi/nextcloud
```

2) **Rename `env.txt` to `.env` and edit values**
```bash
mv env.txt .env
nano .env
```
Fill in real passwords, domains, and mail settings. Keep `.env` out of version control.

3) **Review Nginx host (optional)**
Open `nginx.conf` and adjust `server_name` if you want logs to show your hostname. Public TLS still terminates on your reverse proxy.

4) **Build and start the stack**
```bash
docker compose build
docker compose up -d
```

5) **Access Nextcloud**
- Internal: `http://<HOST>:8080/`
- First-run install occurs automatically if admin and database variables are set in `.env`.

6) **Wire up your reverse proxy**
- Forward your public hostname to `http://<HOST>:8080`.
- Ensure trusted domains and proxies are set in `.env`.

---

## Configuration via `.env` (rename from `env.txt`)

Below is the variable set shipped in `env.txt`. After renaming to `.env`, update each value as appropriate for your environment.

```dotenv
MYSQL_ROOT_PASSWORD=setmysqlrootpassword #change this value and remove this comment
MYSQL_PASSWORD=setmysqlpassword #change this value and remove this comment
MYSQL_DATABASE=setmysqldatabasename #change this value and remove this comment
MYSQL_USER=setmysqldatabaseuser #change this value and remove this comment
MYSQL_HOST=db
REDIS_HOST=redis
PHP_MEMORY_LIMIT=2G
PHP_UPLOAD_LIMIT=10G
PHP_POST_MAX_SIZE=10G
PHP_MAX_EXECUTION_TIME=3600
PHP_MAX_INPUT_TIME=3600
OPCACHE_MEM_SIZE=128
OPCACHE_MAX_ACCELERATED_FILES=10000
OPCACHE_INTERNED_STRINGS_BUFFER=16
OPCACHE_REVALIDATE_FREQ=1
OVERWRITECLIURL=https://yourdomain.com #change this value and remove this comment
OVERWRITEPROTOCOL=https
NEXTCLOUD_TRUSTED_DOMAINS=yourdomain.com localhost nextcloud-app #change the value for 'yourdomain.com' and remove this comment
TRUSTED_PROXIES_NEXTCLOUD=127.0.0.0/8 10.0.0.0/8 172.16.0.0/12 192.168.0.0/16 #you may need to update these values and remove this comment. but you can try without changing first.
SMTP_MODE=smtp #change this value and remove this comment
SMTP_SECURE=ssl #change this value and remove this comment
SMTP_PORT=465 #change this value and remove this comment
MAIL_FROM_ADDRESS=user #change this value and remove this comment
MAIL_DOMAIN=yourdomain.com #change this value and remove this comment
SMTP_HOST=mail.yourdomain.com #change this value and remove this comment
SMTP_NAME=user@yourdomain.com #change this value and remove this comment
SMTP_PASSWORD=youremailpassword #change this value and remove this comment
NEXTCLOUD_ADMIN_USER=admin #change this value and remove this comment
NEXTCLOUD_ADMIN_PASSWORD=Password123$ #change this value and remove this comment
```

> After the stack is up, validate SMTP by sending a test email in **Settings → Administration → Basic settings → Email server**.

---

## Service details

### Nextcloud FPM (`app`)
- Base image: `nextcloud:fpm`
- Adds `ffmpeg` and `imagemagick` for previews/media (per `Dockerfile`)
- Reads database, Redis, PHP limits, trusted domains, overwrite URL/protocol, SMTP, and admin bootstrap from `.env`

### Nginx (`web`)
- Image: `nginx:stable-alpine`
- Mounts `./nginx.conf` at `/etc/nginx/conf.d/default.conf`
- Serves the shared application volume and proxies PHP to `app:9000`
- Includes `.well-known` DAV redirects, security headers, and large upload handling

### MariaDB (`db`)
- Image: `mariadb:10.6`
- Persists data on the database volume
- Startup flags tuned in `docker-compose.yml`

### Redis (`redis`)
- Image: `redis:alpine`
- Used for file locking and caching; referenced via `REDIS_HOST`

### Cron (`cron`)
- Uses the same build as `app`
- Runs `/cron.sh` to execute Nextcloud background jobs
- Shares the application volume and environment

---

## Persistence and backups

- **Volumes**: application code/config/data and database live on named volumes.
- Back up both regularly:
  - Database dump example:
    ```bash
    docker compose exec db sh -c 'mysqldump -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE"' > nextcloud.sql
    ```
  - Application volume: file-level backup of `/var/www/html` (or your external `NEXTCLOUD_DATADIR` if configured).

Store backups off-host and test your restores.

---

## Maintenance

- Update images and rebuild:
  ```bash
  docker compose pull
  docker compose build --no-cache
  docker compose up -d
  ```
- Nextcloud core updates can be run through the web updater; database migrations are handled automatically.

---

## Useful commands

```bash
# Tail logs
docker compose logs -f web
docker compose logs -f app
docker compose logs -f db
docker compose logs -f redis
docker compose logs -f cron

# OCC examples
docker compose exec app php occ status
docker compose exec app php occ app:list

# Shell inside app
docker compose exec app bash
```

---

## Security checklist

- Use strong unique passwords
- Keep `.env` private (never commit it)
- Terminate TLS on your reverse proxy; only expose 443 publicly
- Keep images updated and apply Nextcloud app updates
- Restrict direct access to port 8080

---
