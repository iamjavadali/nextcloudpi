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

Edit `config.php` inside the Nextcloud app volume and add the snippet **before the final `);`**:

```bash
sudo -i
nano /var/lib/docker/volumes/nextcloud_app/_data/config/config.php
```

Append:
```php
  'default_phone_region' => 'US',
  'maintenance_window_start' => 1,
  'enable_previews' => true,
  'enabledPreviewProviders' =>
  array (
    0 => 'OC\Preview\Movie',
    1 => 'OC\Preview\PNG',
    2 => 'OC\Preview\JPEG',
    3 => 'OC\Preview\GIF',
    4 => 'OC\Preview\BMP',
    5 => 'OC\Preview\XBitmap',
    6 => 'OC\Preview\MP3',
    7 => 'OC\Preview\MP4',
    8 => 'OC\Preview\TXT',
    9 => 'OC\Preview\MarkDown',
    10 => 'OC\Preview\PDF',
  ),
```
Save and exit. This resolves the maintenance window and default phone region warnings and enables rich previews. 

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

If Nextcloud warns about blocked WOPI requests from Collabora, you can either allow‑list the exact container IP or a subnet used by your Docker network.

Find the Collabora container IP:
```bash
docker inspect collabora | grep IPAddress
```
Example output includes a line like:
```
"IPAddress": "172.21.0.2",
```
For fewer future changes, allow the subnet (for example `172.21.0.0/16` or the narrower `172.21.0.0/24`). Add these ranges to the **Office → WOPI allow list** in Nextcloud.

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
