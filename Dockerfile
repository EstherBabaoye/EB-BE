# ---- Build stage: install deps with Composer ----
FROM composer:2 AS vendor
WORKDIR /app
COPY composer.json composer.lock ./
RUN composer install --no-dev --no-interaction --no-progress --prefer-dist
COPY . .
RUN composer install --no-dev --no-interaction --no-progress --prefer-dist \
 && php artisan package:discover --ansi || true

# ---- Runtime stage: PHP CLI with needed extensions ----
FROM php:8.2-cli
WORKDIR /app

# System deps (git, unzip, sqlite, etc.)
RUN apt-get update && apt-get install -y \
    libzip-dev unzip git sqlite3 libsqlite3-dev libpng-dev libonig-dev libxml2-dev \
 && docker-php-ext-install pdo pdo_sqlite mbstring tokenizer xml zip \
 && rm -rf /var/lib/apt/lists/*

# Copy app + vendor
COPY . .
COPY --from=vendor /app/vendor /app/vendor

# Laravel optimizations (optional at build)
RUN php artisan config:clear && php artisan route:clear && php artisan cache:clear

# Ensure storage is writable
RUN chown -R www-data:www-data storage bootstrap/cache

# Render sets $PORT; use PHP built-in server
# NOTE: Do not EXPOSE a fixed port on Render; it injects $PORT.
CMD php -S 0.0.0.0:$PORT -t public
