# Snipe-IT Lite — IT Asset Management

Self-hosted IT asset management with SQLite storage. Track laptops, licenses, accessories, and who has what — one container, no database server required.

## Deploy and Host

Host Snipe-IT on Railway. This template provisions Snipe-IT (v8, alpine) with a persistent volume for its SQLite database — single service, Hobby-tier friendly.

[![Deploy to Railway](https://railway.app/button.svg)](https://railway.com/deploy/N5s3z8)

## Why Deploy

Snipe-IT is the open-source standard for IT asset management (50k+ GitHub stars). Running it on Railway gives you:

- **Single container** — SQLite on a volume instead of a separate MySQL/Postgres service
- **Persistent data** — assets, users, and settings survive restarts on a Railway volume
- **Hobby-tier friendly** — 512MB plan runs it; no database server to pay for
- **Full feature set** — asset check-in/check-out, depreciation, licenses, accessories, QR/barcode labels, REST API, LDAP/SAML optional
- **One-click setup** — preboot creates the SQLite database; the web pre-flight wizard finishes in under a minute

## Common Use Cases

- **Small-team IT inventory** — track laptops, phones, and peripherals issued to employees
- **License compliance** — record seats and expirations for software licenses
- **Check-in/check-out auditing** — full history of who held which asset and when
- **Home lab inventory** — keep hardware, VMs, and gear catalogued with photos and warranties
- **Paired with your stack** — REST API for integrating inventory into CMDBs and wikis

### Deployment Dependencies

This template is self-contained — no external services required. All data persists on the service's volume at `/var/lib/snipeit`. The instance is ready out of the box on one-click deploy.

**After first successful deploy:**

1. Open your Railway public domain — you'll be redirected to `/setup` (the Snipe-IT pre-flight wizard)
2. The wizard validates the environment; every check should pass (database file, app key, extensions)
3. Create the first admin user on the final wizard page
4. Log in and start adding assets

## Documentation

Snipe-IT docs: https://snipe-it.readme.io/docs — covers asset lifecycle, labels, LDAP, API keys, and backups.

## Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `APP_KEY` | Laravel encryption key. Auto-generated at deploy. | `${{secret(32)}}` |
| `APP_URL` | Public URL of the instance. Auto-filled with the Railway domain. | `${{RAILWAY_PUBLIC_DOMAIN}}` |
| `DB_CONNECTION` | Database driver. SQLite keeps everything in one container. | `sqlite` |
| `DB_DATABASE` | SQLite file path. Must stay on the volume. | `/var/lib/snipeit/database.sqlite` |
| `APP_ENV` | Laravel environment. | `production` |
| `APP_DEBUG` | Debug output. Keep off in production. | `false` |
| `APP_TRUSTED_PROXIES` | Railway proxy range for correct scheme/HTTPS handling. | `10.0.0.0/8` |
| `SESSION_DRIVER` | Session storage backend. | `file` |
| `MAIL_MAILER` | Mail transport. `log` stores mail in deploy logs until you configure SMTP. | `log` |
| `PHP_FPM_PM_MAX_CHILDREN` | PHP-FPM worker cap. 2 fits small plans. | `2` |
| `PHP_MEMORY_LIMIT` | PHP memory cap. | `256M` |

## Quick Start

After deployment, finish setup in the browser:

```bash
# Check the app is up (expect a 302 to /setup)
curl -I https://your-domain.up.railway.app/
```

1. Visit `https://your-domain.up.railway.app` — redirects to the setup wizard
2. Click through the pre-flight checks (all should be green)
3. Create your admin user and log in
4. Settings → Labels to enable QR/barcode asset tags
5. Optional: Settings → Localization for currency and date formats

API usage (after creating a token in Settings → API):

```bash
# List assets
curl -H "Authorization: Bearer YOUR_TOKEN" \
  https://your-domain.up.railway.app/api/v1/hardware

# Create an asset
curl -X POST -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"asset_tag":"LT-0001","model_id":1,"status_id":1}' \
  https://your-domain.up.railway.app/api/v1/hardware
```

## License

AGPL-3.0 (Snipe-IT upstream)
