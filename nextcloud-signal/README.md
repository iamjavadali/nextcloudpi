# Nextcloud Talk — Signaling Server

High-performance signaling backend for **Nextcloud Talk**, using **NATS** as its message bus. Required to support calls with more than 4 participants.

---

## Quick start

```bash
cp .env.example .env
nano .env   # generate and fill in secrets (see commands below)
docker compose up -d
```

Generate the required secrets:

```bash
# For HASH_KEY and BLOCK_KEY
openssl rand -hex 16

# For INTERNAL_SHARED_SECRET_KEY and BACKENDS_ALLOWALL_SECRET
openssl rand -hex 32
```

The signaling service listens at `http://<host>:8082`. NATS listens at `nats://<host>:4222`.

---

## Configuration (`.env`)

Copy `.env.example` to `.env` and update:

| Variable | Description |
|----------|-------------|
| `TRUSTED_PROXIES_SIGNAL` | CIDR list of your reverse proxy IPs |
| `HASH_KEY` | 16-byte hex encryption key (`openssl rand -hex 16`) |
| `BLOCK_KEY` | 16-byte hex encryption key (`openssl rand -hex 16`) |
| `INTERNAL_SHARED_SECRET_KEY` | 32-byte hex shared secret (`openssl rand -hex 32`) |
| `BACKENDS_ALLOWALL_SECRET` | 32-byte hex secret for backend auth (`openssl rand -hex 32`) |
| `NATS_URL` | NATS URI — leave as `nats://nats:4222` unless customised |

---

## nginx-proxy-manager setup

- **Scheme**: `http`, **Forward hostname**: host IP, **Port**: `8082`
- Enable **Force SSL**, **WebSocket support** — WebSockets are required for Talk signaling
- Add `proxy_buffering off;` in the Advanced tab for real-time performance

---

## NATS configuration

`gnatsd.conf` is mounted into the NATS container. Default settings:
- Client port: `4222`
- HTTP monitoring: `8222` (internal only)
- Auth is present but commented — enable if you expose NATS

---

## Nextcloud integration

In Nextcloud → **Administration → Talk**:

1. Add signaling server: `https://talk.yourdomain.com`
2. Enter the shared secret from `INTERNAL_SHARED_SECRET_KEY`
3. Configure TURN/STUN servers for NAT traversal

---

## Maintenance

```bash
# Update and restart
docker compose pull && docker compose up -d

# Logs
docker compose logs -f signaling nats
```

---

## Security

- Generate unique secrets — never reuse the placeholder values.
- Keep ports 8082, 4222, and 8222 off the public internet — proxy only.
- If exposing NATS externally, enable auth in `gnatsd.conf`.
