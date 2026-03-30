# Collabora Online (CODE) — Docker Stack

Single-container **Collabora Online** server for document editing in Nextcloud. Exposes the WOPI service on port `9980` and runs behind nginx-proxy-manager.

---

## Quick start

```bash
cp .env.example .env
nano .env          # set COLLABORA_DOMAIN, COLLABORA_SERVER_NAME, credentials
docker compose up -d
```

Collabora listens at `http://<host>:9980`. Forward your public HTTPS host to this port via nginx-proxy-manager.

---

## Configuration (`.env`)

Copy `.env.example` to `.env` and update:

| Variable | Description |
|----------|-------------|
| `COLLABORA_DOMAIN` | Your Nextcloud domain with dots escaped: `cloud\\.yourdomain\\.com` |
| `COLLABORA_SERVER_NAME` | Public Collabora hostname: `office.yourdomain.com` |
| `COLLABORA_USERNAME` | Admin console username |
| `COLLABORA_PASSWORD` | Admin console password |
| `COLLABORA_EXTRA_PARAMS` | Runtime flags (SSL termination handled by proxy — leave as-is) |

---

## nginx-proxy-manager setup

- **Scheme**: `http`, **Forward hostname**: your host IP, **Port**: `9980`
- Enable **Force SSL**, **WebSocket support**
- HSTS is optional (Cloudflare handles it if you're using a tunnel)

---

## Nextcloud integration

In Nextcloud → **Administration → Office**:

1. Select **Use your own server**
2. Enter your Collabora URL: `https://office.yourdomain.com`
3. Save and open any document to verify

If WOPI requests are blocked, add the required IP ranges to the WOPI allowlist. If your Collabora domain routes through Cloudflare, add Cloudflare's IPv4 ranges:

```bash
docker exec -u www-data nextcloud-app php occ config:app:set richdocuments wopi_allowlist \
  --value="103.21.244.0/22,103.22.200.0/22,103.31.4.0/22,104.16.0.0/13,104.24.0.0/14,\
108.162.192.0/18,131.0.72.0/22,141.101.64.0/18,162.158.0.0/15,172.64.0.0/13,\
173.245.48.0/20,188.114.96.0/20,190.93.240.0/20,197.234.240.0/22,198.41.128.0/17"
```

---

## Maintenance

```bash
# Update image and restart
docker compose pull && docker compose up -d

# Logs
docker compose logs -f collabora
```

---

## Security

- Set strong admin credentials in `.env`.
- Keep port 9980 off the public internet — proxy only.
- TLS terminates at nginx-proxy-manager, not inside this container.
