# ---- Build stage: install PHP dependencies ----
FROM composer:2 AS vendor
WORKDIR /app

COPY composer.json composer.lock ./
RUN composer install --no-dev --no-interaction --no-progress --prefer-dist --no-scripts

COPY . .
RUN composer install --no-dev --no-interaction --no-progress --prefer-dist --no-scripts --optimize-autoloader \
 && php artisan package:discover --ansi || true

# ---- Runtime stage: PHP only (no DB) ----
FROM php:8.2-cli
WORKDIR /app

# Build tools + TLS; no sqlite, no git, no heavy libs
RUN set -eux; \
    apt-get update -o Acquire::Retries=3; \
    apt-get install -y --no-install-recommends \
        $PHPIZE_DEPS \
        ca-certificates \
    ; \
    rm -rf /var/lib/apt/lists/*

# Needed for Laravel
RUN docker-php-ext-install -j"$(nproc)" mbstring

# Copy app + vendor
COPY . .
COPY --from=vendor /app/vendor /app/vendor

# Writable dirs
RUN mkdir -p bootstrap/cache storage/logs \
 && chown -R www-data:www-data storage bootstrap/cache

# Safe clears at build
RUN php artisan config:clear || true \
 && php artisan route:clear || true \
 && php artisan cache:clear || true

# Boot: clear caches, then serve via router script (so CORS preflight hits Laravel)
CMD sh -c "php artisan config:clear && php artisan route:clear && php artisan cache:clear \
  && php -S 0.0.0.0:$PORT -t public public/index.php"
