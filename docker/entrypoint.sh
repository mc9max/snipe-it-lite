#!/bin/bash
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

# Fix white-on-white: inject data-theme="light" via Apache mod_substitute.
# Runs at HTTP response level, bypassing Railway's build cache entirely.
echo 'LoadModule substitute_module modules/mod_substitute.so' > /etc/apache2/conf.d/load-substitute.conf
echo 'AddOutputFilterByType SUBSTITUTE text/html' > /etc/apache2/conf.d/substitute.conf
# Use heredoc to avoid shell quoting issues with spaces in replacement
cat >> /etc/apache2/conf.d/substitute.conf <<'EOF'
Substitute "s|</head>|<script>document.documentElement.setAttribute('data-theme','light')</script></head>|i"
EOF

# Clear Laravel view cache to ensure blade template changes take effect
cd /var/www/html && php artisan view:clear 2>/dev/null || true

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

exec bash /var/www/html/docker/startup_alpine.sh
