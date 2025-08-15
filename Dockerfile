# ---- Build stage: install deps with Composer (no scripts yet) ----
FROM composer:2 AS vendor
WORKDIR /app

# Install PHP deps (no artisan scripts yet because app not copied)
COPY composer.json composer.lock ./
RUN composer install --no-dev --no-interaction --no-progress --prefer-dist --no-scripts

# Copy app, then finish install & discover packages
COPY . .
RUN composer install --no-dev --no-interaction --no-progress --prefer-dist --no-scripts --optimize-autoloader \
 && php artisan package:discover --ansi || true

# ---- Runtime stage: PHP with required extensions ----
FROM php:8.2-cli
WORKDIR /app

# System deps: only what we actually need at runtime
# - sqlite3 & libsqlite3-dev for DB
# - ca-certificates for TLS
# Use retries to be resilient on Render mirrors
RUN set -eux; \
    apt-get update -o Acquire::Retries=3; \
    apt-get install -y --no-install-recommends \
        sqlite3 \
        libsqlite3-dev \
        ca-certificates \
    ; \
    rm -rf /var/lib/apt/lists/*

# Enable required PHP extensions (no external build deps needed here)
RUN docker-php-ext-install pdo pdo_sqlite mbstring

# Copy app code + vendor from build stage
COPY . .
COPY --from=vendor /app/vendor /app/vendor

# Ensure cache dirs exist and are writable
RUN mkdir -p bootstrap/cache storage/logs \
 && chown -R www-data:www-data storage bootstrap/cache

# Optional: clear caches at build (safe if present)
RUN php artisan config:clear || true \
 && php artisan route:clear || true \
 && php artisan cache:clear || true

# ---- Boot: clear caches, prep SQLite, (try) migrate, then serve via router script ----
# Using public/index.php as router ensures OPTIONS hits Laravel (CORS).
CMD sh -c "php artisan config:clear && php artisan route:clear && php artisan cache:clear \
  && touch /app/storage/database.sqlite \
  && php artisan migrate --force || true \
  && php -S 0.0.0.0:$PORT -t public public/index.php"
