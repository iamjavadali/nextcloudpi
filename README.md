# nextcloudpi

A self-hosted collaboration stack built for **Raspberry Pi 5 (ARM64)** and deployable behind nginx-proxy-manager + Cloudflare Tunnel. Three independent services, each in its own directory.

---

## Services

| Directory | Service | Port |
|-----------|---------|------|
| `nextcloud/` | Nextcloud FPM + Nginx + MariaDB + Redis + Cron | `8080` |
| `collabora/` | Collabora Online (CODE) — document editing | `9980` |
| `nextcloud-signal/` | Nextcloud Talk signaling server + NATS | `8082` |

Each service is self-contained with its own `docker-compose.yml` and `.env.example` → `.env`.

---

## Architecture

```
Internet (HTTPS)
       │
Cloudflare Tunnel
       │
nginx-proxy-manager  (TLS termination, HSTS, Force SSL)
       │
┌──────┼──────────────┬──────────────────┐
│      │              │                  │
▼      ▼              ▼                  ▼
Nextcloud        Collabora (9980)   Signaling (8082)
web:8080                              + NATS (4222)
│
├── app (PHP-FPM)
├── db  (MariaDB 11.8)
├── redis
└── cron
```

---

## Branches

| Branch | Purpose |
|--------|---------|
| `main` | Production deployment — pulls `iamjavadali/nextcloudpi` from Docker Hub |
| `dockerhub` | Jenkins CI/CD — builds the image on RPi5, tests it, pushes to Docker Hub |

---

## Quick start

```bash
git clone https://github.com/iamjavadali/nextcloudpi.git
cd nextcloudpi
```

For each service you want to run:

```bash
cd nextcloud        # or collabora / nextcloud-signal
cp .env.example .env
nano .env           # fill in passwords, domain, SMTP
docker compose up -d
```

See each service's README for full configuration details.

---

## Service READMEs

- [Nextcloud](nextcloud/README.md)
- [Collabora](collabora/README.md)
- [Nextcloud Talk Signaling](nextcloud-signal/README.md)

---

## Post-launch setup

After Nextcloud's first start, run `occ` commands to clear admin panel warnings. See [INSTALL-and-SETUP.md](INSTALL-and-SETUP.md) for the full checklist.

---

## Security

- Never commit `.env` files — they are gitignored.
- Terminate TLS at nginx-proxy-manager; keep port 8080/9980/8082 off the public internet.
- Rotate all generated secrets periodically.

See [SECURITY.md](SECURITY.md) to report vulnerabilities.
