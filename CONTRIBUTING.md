# Contributing to NextcloudPI

Thanks for wanting to help. This repo bundles three services: **Nextcloud**, **Collabora**, and **Nextcloud Talk Signaling**. Each service is self‑contained with its own `docker-compose.yml`, `env.txt` (rename to `.env`), and service‑specific config files.

Before you start, read the [Code of Conduct](CODE_OF_CONDUCT.md).

## Repo layout

```
/nextcloud/     # Nextcloud app stack (Nginx, FPM, MariaDB, Redis, cron)
/collabora/     # Collabora Online (CODE)
/signaling/     # Talk signaling + NATS
/docs/          # Diagrams, notes, screenshots (optional)
```

## Getting started (local)

1. **Prereqs:** Docker + Docker Compose plugin, a DNS domain, and a public reverse proxy (for TLS).
2. **Environment:** in each service directory, rename `env.txt` → `.env` and edit values.
3. **Start:** bring up each service with `docker compose up -d` from its directory.
4. **Reverse proxy:** route public hosts to the internal ports (Nextcloud `:8080`, Collabora `:9980`, Signaling `:8082`) and enable WebSockets.
5. **Integrations:** in Nextcloud Admin, configure Office (Collabora) and Talk (Signaling).

## How to propose changes

- Open an **issue** first for significant changes (architecture, ports, defaults).
- Use a **feature branch** from `main`. Keep commits focused and clear.
- Write/update docs when behavior or configuration changes.
- If you change environment variables, update all READMEs and `env.txt` templates.

### Commit style

- Use concise, imperative messages:
  - `nextcloud: raise client_max_body_size to 10G`
  - `collabora: add example WOPI allowlist note`
- Reference issues with `Fixes #123` when applicable.

### Pull request checklist

- [ ] `docker compose config` passes for all modified compose files
- [ ] README and docs updated for any user‑visible changes
- [ ] No secrets or `.env` committed
- [ ] CI passes (lint/scan), if enabled

## Security

Do **not** disclose vulnerabilities in public issues. See [SECURITY.md](SECURITY.md) for how to report privately.

## License

By contributing, you agree your work will be licensed under the terms in [LICENSE](LICENSE).
