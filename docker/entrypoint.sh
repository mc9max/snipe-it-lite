#!/bin/sh
set -e

# Railway volumes mount root-owned; snipe-it's startup runs chown for its dirs,
# but the sqlite file itself and database dir need to be writable by apache.
mkdir -p /var/lib/snipeit

# Create empty sqlite db file if missing (first deploy)
if [ ! -f /var/lib/snipeit/database.sqlite ]; then
  echo "Creating empty SQLite database at /var/lib/snipeit/database.sqlite..."
  : > /var/lib/snipeit/database.sqlite
fi

# Ensure apache owns the db file and data dirs
chown apache:root /var/lib/snipeit/database.sqlite /var/lib/snipeit
chmod 664 /var/lib/snipeit/database.sqlite

# Symlink into the app's expected location (idempotent; Dockerfile also sets it)
ln -sf /var/lib/snipeit/database.sqlite /var/www/html/database/database.sqlite
chown -h apache:root /var/www/html/database/database.sqlite 2>/dev/null || true

# Laravel needs the database dir writable for sqlite journal files
chown apache:root /var/www/html/database 2>/dev/null || true

# Hand off to upstream startup script:
# - creates /var/lib/snipeit/data/* dirs, chowns them
# - runs php artisan migrate --force
# - execs httpd -DNO_DETACH
# (invoked via sh because the upstream file is not +x in the image)
# Force Railway's X-Forwarded-Proto: https to be seen as HTTPS by PHP.
# Without this, Laravel's request()->url() returns http:// and the pre-flight
# wizard fails because it can't reconcile APP_URL (https) with request URL (http).
echo 'SetEnv HTTPS on' > /etc/apache2/conf.d/forwarded-https.conf

# Suppress AH00558: httpd: Could not reliably determine the server's FQDN.
echo 'ServerName localhost' > /etc/apache2/conf.d/servername.conf

exec sh /var/www/html/docker/startup_alpine.sh
