# ---- Build stage: install PHP dependencies ----
FROM composer:2 AS vendor
WORKDIR /app

# Copy composer files & install dependencies
COPY composer.json composer.lock ./
RUN composer install --no-dev --no-interaction --no-progress --prefer-dist --no-scripts

# Copy app source
COPY . .

# Discover packages (optimize autoloader)
RUN composer install --no-dev --no-interaction --no-progress --prefer-dist --no-scripts --optimize-autoloader \
 && php artisan package:discover --ansi || true

# ---- Runtime stage: PHP ----
FROM php:8.2-cli
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    libzip-dev unzip git libpng-dev libxml2-dev \
 && docker-php-ext-install pdo mbstring xml zip \
 && rm -rf /var/lib/apt/lists/*

# Copy app + vendor
COPY . .
COPY --from=vendor /app/vendor /app/vendor

# Ensure cache dirs exist and writable
RUN mkdir -p bootstrap/cache storage/logs \
 && chown -R www-data:www-data storage bootstrap/cache

# Clear caches
RUN php artisan config:clear || true \
 && php artisan route:clear || true \
 && php artisan cache:clear || true

# ---- Run server ----
CMD ["php", "-S", "0.0.0.0:10000", "-t", "public", "public/index.php"]
