# Collabora Online (CODE) — Docker Stack

This repository runs a single **Collabora Online** server (CODE) suitable for integrating with Nextcloud Office. Configuration is environment-driven via `env.txt` which you **rename to `.env`** before starting.

> Repo files used here: `docker-compose.yml`, `env.txt` (rename to `.env`).

---

## What this stack does

- Launches **collabora/code:latest** exposing the WOPI service on host port **9980** → container `9980`.
- Reads admin, domain, and runtime flags from `.env`.
- Persists configuration and logs on a named volume (`collabora`).

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
Update the Collabora variables for your setup (domains, admin, password, and extra params).

3) **Start the server**
```bash
docker compose up -d
```

4) **Health check**
```bash
docker compose logs -f collabora
```

The container listens on `http://<HOST>:9980`. Put your public HTTPS reverse proxy in front of it.

---

## Environment reference (from `env.txt`)

These variables configure Collabora. Rename `env.txt` to `.env` and edit the values:

```dotenv
# ---- COLLABORA DASHBOARD ----
COLLABORA_DOMAIN=cloud\\.yourdomain\\.com  #change this to your nextcloud domain.
COLLABORA_USERNAME=admin
COLLABORA_PASSWORD=Password$123
COLLABORA_EXTRA_PARAMS=--o:ssl.enable=false --o:ssl.termination=true --o:welcome.enable=false --o:net.proxy_prefix=true
COLLABORA_SERVER_NAME=collabora.yourdomain.com #change this to your collabora domain.
```

---

## Reverse proxy notes

- Terminate TLS at your proxy and forward to `http://<HOST>:9980`.
- Use your public Collabora hostname in DNS, and set it in `.env` (server name and allowed domain).
- If you change port or hostname, reflect that in your proxy and Nextcloud settings.

---

## Nextcloud integration (Office app)

In Nextcloud → **Administration settings → Office**:
- Choose **Use your own server** and enter your Collabora URL, for example `https://<your-collabora-domain>` or `https://<your-host>:9980`.
- If WOPI requests are blocked by your proxy provider, add the required ranges to the allow list in Nextcloud as instructed by its warnings.
- Test by opening a document in Files.

---

## Persistence & data

- Named volume `collabora` stores Collabora configuration and logs.
- To reset the server, stop the container and remove the volume, then re-create it.

---

## Maintenance

```bash
# Update image and restart
docker compose pull
docker compose up -d
# Inspect logs
docker compose logs -f collabora
```

---

## Security checklist

- Put a trusted TLS certificate on your reverse proxy.
- Set strong admin credentials in `.env`.
- Restrict who can reach port 9980 directly; expose only HTTPS on the proxy.

---

## License

Add a `LICENSE` file (e.g., MIT) to match your repository terms.
