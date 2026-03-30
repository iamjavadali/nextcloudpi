# Nextcloud — Docker Stack

Nextcloud FPM running behind Nginx, with MariaDB, Redis, and a cron worker. Designed for **Raspberry Pi 5 (ARM64)** and deployment behind nginx-proxy-manager.

---

## Architecture

```
nginx-proxy-manager
        │  (HTTP → port 8080)
        ▼
  nextcloud-web  (nginx:stable-alpine, FastCGI)
        │
        ▼
  nextcloud-app  (iamjavadali/nextcloudpi, PHP-FPM :9000)
        │
   ┌────┴────┐
   ▼         ▼
nextcloud-db  nextcloud-redis
(MariaDB 11.8) (redis:alpine)
```

`nextcloud-cron` shares the `app` volume and runs background jobs via `/cron.sh`.

---

## Quick start

```bash
cp .env.example .env
nano .env          # set passwords, domain, SMTP
docker compose up -d
```

Nextcloud becomes available at `http://<host>:8080`. Wire your reverse proxy to this port with Force SSL and HSTS enabled at the proxy level.

---

## Configuration (`.env`)

Copy `.env.example` to `.env` and update these values at minimum:

| Variable | Description |
|----------|-------------|
| `MYSQL_ROOT_PASSWORD` | MariaDB root password |
| `MYSQL_PASSWORD` | MariaDB app user password |
| `NEXTCLOUD_ADMIN_USER` | Initial admin username |
| `NEXTCLOUD_ADMIN_PASSWORD` | Initial admin password (must include uppercase, number, special char) |
| `OVERWRITECLIURL` | Your public URL, e.g. `https://cloud.yourdomain.com` |
| `OVERWRITEPROTOCOL` | `https` when behind a TLS proxy |
| `NEXTCLOUD_TRUSTED_DOMAINS` | Space-separated list of allowed hostnames/IPs |

---

## Networking

- `nextcloud-web` is on both the internal `nextcloud` network and the external `proxy` network (shared with nginx-proxy-manager).
- `nextcloud-db`, `nextcloud-redis`, `nextcloud-cron` are internal only — not reachable from outside the stack.

---

## Data directories

Data is stored in **bind mounts** alongside the compose file:

| Path | Contents |
|------|----------|
| `./app/` | Nextcloud PHP files, config, and user data |
| `./db/` | MariaDB data files |

Both directories are gitignored. Back them up regularly.

```bash
# Database backup
docker exec nextcloud-db sh -c \
  'mysqldump -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE"' > backup.sql
```

---

## ARM64 notes (Raspberry Pi 5)

The `iamjavadali/nextcloudpi` image fixes two issues present in the upstream `nextcloud:fpm` image on aarch64:

- **imagick SIGSEGV** — upstream ships the extension compiled for x86_64; the image recompiles it via PECL for ARM64.
- **OPcache JIT SIGSEGV** — PHP 8.x JIT is unstable on ARM64; disabled via `zzz-arm64-jit-disable.ini`.

---

## Post-first-launch setup

After logging in for the first time, run these `occ` commands to clear administration warnings. See [INSTALL-and-SETUP.md](../INSTALL-and-SETUP.md) for the full list.

```bash
docker exec -u www-data nextcloud-app php occ config:system:set default_phone_region --value="US"
docker exec -u www-data nextcloud-app php occ config:system:set maintenance_window_start --type=integer --value=1
docker exec -u www-data nextcloud-app php occ db:add-missing-indices
```

---

## Useful commands

```bash
# Logs
docker compose logs -f web app db

# OCC
docker exec -u www-data -it nextcloud-app php occ status
docker exec -u www-data -it nextcloud-app php occ app:list

# Shell
docker exec -it nextcloud-app bash

# Update (pull new image)
docker compose pull && docker compose up -d
```

---

## Building locally

A `Dockerfile` is included if you want to build the image yourself instead of pulling from Docker Hub:

```bash
docker build -t iamjavadali/nextcloudpi:local .
# Then in docker-compose.yml replace image: with build: context: .
```
