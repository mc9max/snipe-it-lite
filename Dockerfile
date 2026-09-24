FROM snipe/snipe-it:latest-alpine

LABEL org.opencontainers.image.source=https://github.com/mc9max/snipe-it-lite

# Install PHP SQLite PDO driver (not included in base alpine image)
RUN apk add --no-cache php84-pdo_sqlite bash

# Fix white-on-white text: upstream setup layout has a duplicate <html> tag without
# data-theme="light". Without it, --box-bg is undefined (white bg) and --color-fg
# follows OS preference (white in dark mode) → invisible text.
COPY resources/views/layouts/setup.blade.php /var/www/html/resources/views/layouts/setup.blade.php

# Ensure the sqlite database file is on the persistent volume.
# config/database.php hardcodes the sqlite path to database_path('database.sqlite')
# which resolves to /var/www/html/database/database.sqlite. We symlink that to
# the Railway volume mount at /var/lib/snipeit so the DB survives restarts.
RUN mkdir -p /var/lib/snipeit && \
    ln -sf /var/lib/snipeit/database.sqlite /var/www/html/database/database.sqlite

# Custom entrypoint: ensures apache can write to the volume paths, then
# runs the upstream startup script which does migrations and starts httpd.
COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
