# NextcloudPi Full Stack (Nextcloud + Collabora + Talk Signaling)

A production-friendly collection of Dockerized services for a complete self‑hosted collaboration setup on Raspberry Pi 4 or 5:
- **Nextcloud core** (FPM + Nginx, MariaDB, Redis, cron)
- **Collabora Online** (CODE) for document editing
- **Nextcloud Talk Signaling** service with NATS

Each service is self-contained with its own `docker-compose.yml` and `.env` (created by renaming `env.txt`). Deploy them together or individually, behind your public HTTPS reverse proxy.

---

## What’s included

- **Nextcloud app stack**: Nginx reverse proxy (container), Nextcloud FPM app image, MariaDB, Redis, and a dedicated cron worker. Uses an environment-first setup by renaming `env.txt` to `.env`. fileciteturn5file0
- **Collabora Online (CODE)**: WOPI server for Office document editing, exposed on host port 9980 by default; configured via `.env` (renamed from `env.txt`). fileciteturn5file1
- **Nextcloud Talk Signaling + NATS**: High-performance signaling backend for Talk with WebSocket forwarding, and a NATS message bus. Configuration via `.env` plus a `gnatsd.conf`.

---

## Reference architecture

```
                         Internet (HTTPS)
                               │
                       Public Reverse Proxy
                 (TLS, SNI routes, WebSockets)
    ┌──────────────────────┬──────────────────────────┬──────────────────────┐
    │ cloud.example.com    │ office.example.com       │ talk.example.com     │
    ▼                      ▼                          ▼
Nextcloud Web         Collabora (9980)           Signaling (8082)
(Nginx → FPM 8080)                               + NATS (4222/8222)
       │                      │                          │
   Nextcloud FPM         (no DB)                     Nextcloud servers
       │                                                (clients connect via WS)
 ┌─────┴─────┐
 │  MariaDB  │
 │   Redis   │
 └───────────┘
```

**Default container ports**
- Nextcloud web: `8080` (HTTP to bundled Nginx)
- Collabora: `9980` (HTTP WOPI)
- Signaling: `8082` (HTTP WS), NATS client: `4222`, NATS monitor: `8222`
> Terminate TLS at your public proxy and forward HTTP/WS to these internal endpoints.

---

## Repo layout

Suggested structure if you’re keeping all services in one repo:

```
/nextcloud/     # Nextcloud app stack (Nginx, FPM, MariaDB, Redis, cron)
/collabora/     # Collabora Online (CODE)
/signaling/     # Nextcloud Talk signaling + NATS
```

Each directory contains:
- `docker-compose.yml`
- `env.txt` → rename to `.env` and edit values
- Service‑specific configs (for example, `nginx.conf` in Nextcloud; `gnatsd.conf` in signaling)

See the service READMEs for details: Nextcloud, Collabora, and Signaling.

---

## Deployment

1) **Prepare environments**  
For each service directory:
```bash
cd <service-dir>
mv env.txt .env
nano .env   # update secrets, domains, networks, mail, etc.
```

2) **Start services**  

> **First time only:** if you haven’t already renamed and edited the environment files, do it now **before** bringing each service up.

```bash
# For each service directory
cd nextcloud    && mv -n env.txt .env && nano .env && cd -
cd collabora    && mv -n env.txt .env && nano .env && cd -
cd signaling    && mv -n env.txt .env && nano .env && cd -
```

**Minimum variables to review per service**

- **Nextcloud (`nextcloud/.env`)**
  - `MYSQL_HOST`, `MYSQL_DATABASE`, `MYSQL_USER`, `MYSQL_PASSWORD`
  - `NEXTCLOUD_ADMIN_USER`, `NEXTCLOUD_ADMIN_PASSWORD`
  - `NEXTCLOUD_TRUSTED_DOMAINS` (include your public hostname)
  - `TRUSTED_PROXIES_NEXTCLOUD` (CIDR(s) for your reverse proxy)
  - `OVERWRITECLIURL` (e.g., `https://cloud.example.com`), `OVERWRITEPROTOCOL=https`
  - Optional: `REDIS_HOST=redis`, SMTP settings for email

- **Collabora (`collabora/.env`)**
  - `COLLABORA_DOMAIN` (the Nextcloud domain Collabora may serve)
  - `COLLABORA_SERVER_NAME` (public Collabora hostname)
  - `COLLABORA_USERNAME`, `COLLABORA_PASSWORD` (admin console)
  - Optional: `COLLABORA_EXTRA_PARAMS`

- **Signaling (`signaling/.env`)**
  - `HTTP_LISTEN=:8082` (or your chosen port behind the proxy)
  - `NATS_URL=nats://nats:4222`
  - Secrets: `HASH_KEY`, `BLOCK_KEY`, `INTERNAL_SHARED_SECRET_KEY`, `BACKENDS_ALLOWALL_SECRET`
  - `TRUSTED_PROXIES_SIGNAL` (CIDR(s) for your reverse proxy)
```

Now start each service:
  
Order is flexible, but this is a sensible flow:
```bash
# Nextcloud
cd nextcloud
docker compose build
docker compose up -d

# Collabora
cd ../collabora
docker compose up -d

# Signaling
cd ../signaling
docker compose up -d
```
Nextcloud becomes available on `http://<host>:8080`, Collabora on `http://<host>:9980`, and the signaling service on `http://<host>:8082`. Put them behind your reverse proxy.

3) **Wire the reverse proxy**  
- `cloud.example.com` → Nextcloud web `:8080`
- `office.example.com` → Collabora `:9980`
- `talk.example.com` → Signaling `:8082` (ensure WebSockets are forwarded)
Update each `.env` to include trusted proxies/domains as noted in the service READMEs.

---

## Integrations inside Nextcloud

- **Office integration**: in Nextcloud → Administration → Office, select “Use your own server” and enter your Collabora URL (the public HTTPS host you routed to `:9980`).
- **Talk high‑performance backend**: in Nextcloud → Administration → Talk, set the Signaling server URL to your public signaling host (the one routed to `:8082`). Configure TURN/STUN for NAT traversal.

---

## Health checks and common commands

```bash
# Logs
docker compose -f nextcloud/docker-compose.yml logs -f web app db redis cron
docker compose -f collabora/docker-compose.yml logs -f collabora
docker compose -f signaling/docker-compose.yml logs -f signaling nats

# OCC in Nextcloud
docker compose -f nextcloud/docker-compose.yml exec app php occ status
docker compose -f nextcloud/docker-compose.yml exec app php occ app:list
```
Service‑specific README files include more commands and details. 

---

## Backups (minimum viable)

- **Nextcloud**: back up the DB (SQL dumps) and the app/data volume. 
- **Collabora**: back up the named volume storing configuration/logs. 
- **Signaling/NATS**: back up signaling env values and your `gnatsd.conf`.

Test restores on a non‑prod host before you need them.

---

## Security checklist

- Don’t commit `.env` files. Generate strong secrets and rotate periodically.
- Terminate TLS at the reverse proxy; only 443 should be public.
- Restrict direct access to Collabora `:9980`, Signaling `:8082`, and NATS `:4222/:8222` to internal networks.
- For Talk Signaling, generate fresh random keys and consider enabling NATS auth.

---

## Maintenance

- Pull images and restart per service:
```bash
docker compose -f nextcloud/docker-compose.yml pull && docker compose -f nextcloud/docker-compose.yml up -d
docker compose -f collabora/docker-compose.yml pull && docker compose -f collabora/docker-compose.yml up -d
docker compose -f signaling/docker-compose.yml pull && docker compose -f signaling/docker-compose.yml up -d
```
Each service README includes update guidance (Nextcloud also uses the web updater for core/app updates).

---

## License

Add a `LICENSE` file (e.g., MIT) aligned with your repository terms.
