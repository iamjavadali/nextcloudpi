# Contributing to nextcloudpi

Thanks for helping. This repo contains three independent services: **Nextcloud**, **Collabora**, and **Nextcloud Talk Signaling**. Each lives in its own directory with its own `docker-compose.yml` and `.env.example`.

Before you start, read the [Code of Conduct](CODE_OF_CONDUCT.md).

---

## Repo layout

```
nextcloud/           # Nextcloud FPM + Nginx + MariaDB + Redis + Cron
collabora/           # Collabora Online (CODE)
nextcloud-signal/    # Talk signaling server + NATS
Jenkins/             # Jenkins CI/CD pipeline
```

Each service directory contains:
- `docker-compose.yml`
- `.env.example` → copy to `.env` and edit before starting
- Service-specific config files (`nginx.conf`, `gnatsd.conf`, etc.)

---

## Getting started

1. **Prerequisites**: Docker + Docker Compose plugin, a domain, a reverse proxy for TLS.
2. **Environment**: in each service directory, `cp .env.example .env` and fill in values.
3. **Start**: `docker compose up -d` from the service directory.
4. **Reverse proxy**: route public hostnames to the internal ports and enable WebSockets for Talk.
5. **Integrations**: configure Nextcloud Office (Collabora) and Talk (Signaling) in the admin panel.

---

## Proposing changes

- Open an **issue** before significant changes (architecture, ports, defaults, new services).
- Work on a **feature branch** from `main`.
- Keep commits focused — one logical change per commit.
- Update READMEs and `.env.example` templates whenever behavior or variables change.

### Commit style

Short, imperative subject line scoped to the service:

```
nextcloud: upgrade MariaDB to 11.8
collabora: add WOPI allowlist example
signal: replace real example secrets with placeholders
```

Reference issues with `Fixes #123` where applicable.

### Pull request checklist

- [ ] `docker compose config` passes for any modified compose file
- [ ] README updated for any user-visible change
- [ ] `.env.example` updated if variables were added, removed, or renamed
- [ ] No `.env` files or secrets committed
- [ ] CI passes (if enabled)

---

## Security

Do **not** open public issues for vulnerabilities. See [SECURITY.md](SECURITY.md) for private reporting.

## License

By contributing you agree your work is licensed under the terms in [LICENSE](LICENSE).
