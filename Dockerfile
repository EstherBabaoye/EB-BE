# ---- Build stage: install deps with Composer (no scripts yet) ----
FROM composer:2 AS vendor
WORKDIR /app

# 1) Copy only composer files first, install dependencies WITHOUT scripts
COPY composer.json composer.lock ./
RUN composer install --no-dev --no-interaction --no-progress --prefer-dist --no-scripts

# 2) Copy the rest of the app, then re-run install (still safe), then discover packages
COPY . .
RUN composer install --no-dev --no-interaction --no-progress --prefer-dist --no-scripts --optimize-autoloader \
 && php artisan package:discover --ansi || true

# ---- Runtime stage: PHP with required extensions ----
FROM php:8.2-cli
WORKDIR /app

# System deps (sqlite, zip, etc.)
RUN apt-get update && apt-get install -y \
    libzip-dev unzip git sqlite3 libsqlite3-dev libpng-dev libonig-dev libxml2-dev \
 && docker-php-ext-install pdo pdo_sqlite mbstring xml zip \
 && rm -rf /var/lib/apt/lists/*

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

# Render sets $PORT dynamically; serve the app
CMD php -S 0.0.0.0:$PORT -t public
