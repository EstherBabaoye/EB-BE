# ---- Build stage: install PHP dependencies (no artisan calls) ----
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

# Build tools + TLS + oniguruma for mbstring
RUN set -eux; \
    apt-get update -o Acquire::Retries=3; \
    apt-get install -y --no-install-recommends \
        $PHPIZE_DEPS \
        libonig-dev \
        pkg-config \
        ca-certificates \
    ; \
    rm -rf /var/lib/apt/lists/*

# Build required PHP extensions (PDO core is built-in)
RUN docker-php-ext-install -j"$(nproc)" mbstring

# Copy app + vendor from build stage
COPY . .
COPY --from=vendor /app/vendor /app/vendor

# (Safety) If a local .env slipped into the repo, don't let it affect runtime
# Comment this line out if you really need to ship a .env, but better to keep it out of git.
RUN rm -f .env || true

# Writable dirs
RUN mkdir -p bootstrap/cache storage/logs \
 && chown -R www-data:www-data storage bootstrap/cache

# ---- Boot: only run artisan at runtime (after Render env vars exist) ----
# Serve via router script so OPTIONS hits Laravel (CORS headers apply).
CMD sh -c "php artisan config:clear || true \
  && php artisan route:clear || true \
  && php artisan cache:clear || true \
  && php -S 0.0.0.0:$PORT -t public public/index.php"
