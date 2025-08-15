# ---- Build stage: install deps with Composer (no scripts yet) ----
FROM composer:2 AS vendor
WORKDIR /app

# 1) Install PHP deps without running artisan scripts (artisan not copied yet)
COPY composer.json composer.lock ./
RUN composer install --no-dev --no-interaction --no-progress --prefer-dist --no-scripts

# 2) Copy app, then finish install & discover packages
COPY . .
RUN composer install --no-dev --no-interaction --no-progress --prefer-dist --no-scripts --optimize-autoloader \
 && php artisan package:discover --ansi || true

# ---- Runtime stage: PHP with required extensions ----
FROM php:8.2-cli
WORKDIR /app

# System deps (sqlite, zip, etc.)
RUN apt-get update && apt-get install -y \
    libzip-dev unzip git sqlite3 libsqlite3-dev libpng-dev libxml2-dev \
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

# ---- Run: clear caches, (optionally) prep SQLite + migrate, then serve via router script ----
# The router script (public/index.php) ensures OPTIONS hits Laravel (needed for CORS).
CMD sh -c "php artisan config:clear && php artisan route:clear && php artisan cache:clear \
  && touch /app/storage/database.sqlite \
  && php artisan migrate --force || true \
  && php -S 0.0.0.0:$PORT -t public public/index.php"
