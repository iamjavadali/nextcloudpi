# NextcloudPi — Install & Post‑Install Setup (Nginx Proxy Manager)

This guide walks through bringing up the Nextcloud stack, first‑time access, and the common post‑install fixes and integrations.

> These steps are derived from the project’s install notes and post‑install checklist. See the original notes for context and examples.

---

## 1) Start the stack

```bash
# from the nextcloud service directory
docker compose up -d
```
Wait about a minute, then open your site:

```
https://cloud.yourdomain.com/
```

Log in with the **admin credentials** you set in your `.env` file. 

---

## 2) Fix common warnings (Administration → Overview)

If you see background job warnings, give it a few minutes for the first cron to run. The steps below clear the usual “maintenance window,” “phone region,” and preview issues.

### 2.1 Set maintenance window, phone region, and preview providers

Run these `occ` commands after the stack is up and you've logged in:

```bash
# Locale and maintenance window
docker exec -u www-data nextcloud-app php occ config:system:set default_phone_region --value="US"
docker exec -u www-data nextcloud-app php occ config:system:set maintenance_window_start --type=integer --value=1

# Unique identifier for this instance (useful if ever scaling to multiple PHP nodes)
docker exec nextcloud-app php occ config:system:set server_id \
  --value="nextcloud-pi5-primary"

# Enable previews and register providers (requires ffmpeg in the image for video thumbnails)
docker exec -u www-data nextcloud-app php occ config:system:set enable_previews --type=boolean --value=true
docker exec -u www-data nextcloud-app php occ config:system:set enabledPreviewProviders 0 --value="OC\\Preview\\Movie"
docker exec -u www-data nextcloud-app php occ config:system:set enabledPreviewProviders 1 --value="OC\\Preview\\PNG"
docker exec -u www-data nextcloud-app php occ config:system:set enabledPreviewProviders 2 --value="OC\\Preview\\JPEG"
docker exec -u www-data nextcloud-app php occ config:system:set enabledPreviewProviders 3 --value="OC\\Preview\\GIF"
docker exec -u www-data nextcloud-app php occ config:system:set enabledPreviewProviders 4 --value="OC\\Preview\\BMP"
docker exec -u www-data nextcloud-app php occ config:system:set enabledPreviewProviders 5 --value="OC\\Preview\\XBitmap"
docker exec -u www-data nextcloud-app php occ config:system:set enabledPreviewProviders 6 --value="OC\\Preview\\MP3"
docker exec -u www-data nextcloud-app php occ config:system:set enabledPreviewProviders 7 --value="OC\\Preview\\MP4"
docker exec -u www-data nextcloud-app php occ config:system:set enabledPreviewProviders 8 --value="OC\\Preview\\TXT"
docker exec -u www-data nextcloud-app php occ config:system:set enabledPreviewProviders 9 --value="OC\\Preview\\MarkDown"
docker exec -u www-data nextcloud-app php occ config:system:set enabledPreviewProviders 10 --value="OC\\Preview\\PDF"
```

This resolves the maintenance window and default phone region warnings and enables rich previews.

### 2.2 Run mimetype migrations

```bash
docker exec -u www-data -it nextcloud-app php occ maintenance:repair --include-expensive
```
This clears the “one or more mimetype migrations are available” warning.

---

## 3) Enable Talk high‑performance backend (Signaling)

After installing the **Talk** app, you’ll see a warning about no high‑performance backend configured. Add your signaling server URL and shared secret:

```bash
docker exec -u www-data nextcloud-app   php occ talk:signaling:add https://signal.yourdomain.com <shared-secret>
```
Replace `<shared-secret>` with your real value. 

---

## 4) Useful commands

```bash
# shell inside container
docker exec -it nextcloud-app /bin/bash
docker exec -it nextcloud-app sh

# database indices and Memories maps
docker exec -u www-data -it nextcloud-app php occ db:add-missing-indices
docker exec -u www-data -it nextcloud-app php occ memories:places-setup
```

---

## 5) Collabora WOPI requests (allow‑listing)

If Nextcloud warns about blocked WOPI requests from Collabora, allow‑list the IP ranges that your Collabora server resolves from.

**If running behind Cloudflare** (Collabora domain routes through Cloudflare), set the allowlist to Cloudflare's published IPv4 ranges:

```bash
docker exec -u www-data nextcloud-app php occ config:app:set richdocuments wopi_allowlist \
  --value="103.21.244.0/22,103.22.200.0/22,103.31.4.0/22,104.16.0.0/13,104.24.0.0/14,108.162.192.0/18,131.0.72.0/22,141.101.64.0/18,162.158.0.0/15,172.64.0.0/13,173.245.48.0/20,188.114.96.0/20,190.93.240.0/20,197.234.240.0/22,198.41.128.0/17"
```

**If running directly on the same Docker network** (no Cloudflare in front of Collabora), allow the Docker subnet instead:

```bash
docker inspect collabora | grep IPAddress
# Then set the /16 or /24 subnet in Nextcloud → Administration → Office → WOPI allow list
```

---

## 6) Nginx Proxy Manager examples

Below are example proxy host entries for common services. Adjust hostnames and upstreams for your environment.

### Nextcloud
- Hostname: `cloud.yourdomain.com`
- Scheme/upstream: `http` → `nextcloud-app:80`
- Options: enable **Force SSL**, **HTTP/2**, **HSTS**, **WebSocket support**
- Advanced: increase upload size
  ```nginx
  client_max_body_size 10G;
  ```

### Signaling (Talk backend)
- Hostname: `signal.yourdomain.com`
- Scheme/upstream: `http` → `signaling:8080`
- Options: enable **Force SSL**, **HTTP/2**, **HSTS**, **WebSocket support**
- Advanced:
  ```nginx
  # Allow larger payloads if needed
  client_max_body_size 100M;
  # Real‑time signaling works better without proxy buffering
  proxy_buffering off;
  ```

### Collabora
- Hostname: `office.yourdomain.com`
- Scheme/upstream: `http` → `collabora:9980`
- Options: enable **Force SSL**, **WebSocket support**
- Advanced: optionally allow large payloads
  ```nginx
  client_max_body_size 10240M;
  ```

> Tip: you can also add `.well-known` DAV redirects in the proxy for Nextcloud if needed.

---

## 7) Security check

After fixes, run the Nextcloud **security scan** and review the Overview page for any remaining warnings.
---

### Notes
- Replace all example domains and secrets with your own values.
- If your Docker network or service names differ, update upstream targets accordingly.
