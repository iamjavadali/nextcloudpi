# Nextcloud Talk — Signaling Server (Docker Stack)

This repository runs a **Nextcloud Talk high‑performance signaling server** with **NATS** as its message bus. Configuration is environment‑driven via `env.txt` which you **rename to `.env`** before starting.

> Repo files used here: `docker-compose.yml`, `env.txt` (rename to `.env`), and `gnatsd.conf`.

---

## What this stack provides

- **signaling**: ghcr.io/strukturag/nextcloud-spreed-signaling:latest exposing host port **8082** → container 8080
- **nats**: nats:2.10 exposing

- Reads secrets and runtime flags from `.env` and uses `gnatsd.conf` for the NATS server.
- Intended to sit behind a public reverse proxy providing HTTPS and WebSocket forwarding.

---

## Quick start

1) **Clone and enter the repo**
```bash
git clone <your-repo-url>
cd <repo-directory>
```

2) **Rename and edit your environment file**
```bash
mv env.txt .env
nano .env
```
Update signaling secrets, trusted proxies, and the `NATS_URL`. The sample shows HTTP listen on `:8080` and a NATS URI of `nats://nats:4222`.

3) **Start the services**
```bash
docker compose up -d
```

4) **Health check**
```bash
docker compose logs -f signaling
docker compose logs -f nats
```

The signaling service listens on `http://<HOST>:8082` and NATS on `nats://<HOST>:4222`.

---

## Environment reference (from `env.txt`)

Rename `env.txt` to `.env` and edit the values. The provided template includes keys like the HTTP bind, trusted proxies, encryption keys, and NATS URL:

```dotenv
# ---- SIGNALING (Nextcloud Talk) ----
SIGNALING_SERVER=signaling:8080
HTTP_LISTEN=:8080
TRUSTED_PROXIES_SIGNAL=127.0.0.0/8,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16
HASH_KEY=c0d3babe75e04f9984a37a9d66f24f367a8d9d3c218fb3be4c7e243e1ed9db42
BLOCK_KEY=38c153facd7a14a9e9f3f66035cce2d5
INTERNAL_SHARED_SECRET_KEY=874ef79f49f949d819a7e25d478b6d1283c37cf9585fcb0e3bb4740cfe77a84f
BACKENDS_ALLOWALL=true
BACKENDS_ALLOWALL_SECRET=874ef79f49f949d819a7e25d478b6d1283c37cf9585fcb0e3bb4740cfe77a84f
NATS_URL=nats://nats:4222
# Use 'openssl rand -hex 16' to generate random hexadecimal keys for the HASH_KEY and BLOCK_KEY parameters
# Use 'openssl rand -hex 32' to generate random hexadecimal keys for the INTERNAL_SHARED_SECRET and BACKEND_ALLOWALL_SECRET
```

> Use `openssl rand -hex 16` for `HASH_KEY` and `BLOCK_KEY`, and `openssl rand -hex 32` for `INTERNAL_SHARED_SECRET_KEY` and `BACKENDS_ALLOWALL_SECRET` as noted in the template comments.

---

## NATS configuration (`gnatsd.conf`)

- Default client port: **4222**
- Optional monitoring endpoint: **8222**
- Auth stanza is present but commented; enable user/password or token as needed.
- Sensible limits for connections and payload size are provided.

Keep `gnatsd.conf` mounted for the NATS container so changes persist across restarts.

---

## Reverse proxy notes

- Terminate TLS at your proxy and forward both HTTP and **WebSocket** traffic to `http://<HOST>:8082`.
- Add your proxy networks to `TRUSTED_PROXIES_SIGNAL` in `.env` so real client IPs and scheme are honored.
- If you expose NATS publicly (not recommended), restrict by firewall and enable authentication in `gnatsd.conf`.

---

## Nextcloud integration (Talk)

In Nextcloud: **Administration settings → Talk**

- Set the **High‑Performance Backend / Signaling server URL** to your public signaling endpoint, for example `https://talk-signal.example.com`.
- Ensure your TURN/STUN server is configured under **Talk → TURN servers** for NAT traversal.
- Test by starting a call; watch the signaling container logs for connection events.

---

## Maintenance

```bash
# Update images and restart
docker compose pull
docker compose up -d

# Logs
docker compose logs -f signaling
docker compose logs -f nats
```

---

## Security checklist

- Generate fresh random keys for all secrets in `.env`.
- Put a trusted TLS certificate on your reverse proxy.
- Limit direct access to ports 8082, 4222, and 8222 to your internal network.
- If exposing NATS, enable auth in `gnatsd.conf`.

---

## License

Add a `LICENSE` file (e.g., MIT) to match your repository terms.
