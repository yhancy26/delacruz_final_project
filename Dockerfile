# --------------------------------------------------
# Stage 1: Build frontend assets using Node
# --------------------------------------------------
FROM node:20-alpine AS frontend


WORKDIR /app


COPY package.json package-lock.json ./


RUN npm ci


COPY resources ./resources
COPY public ./public
COPY vite.config.js ./


RUN npm run build


# Verify that Vite generated the manifest
RUN test -f public/build/manifest.json \
    && echo "Frontend build completed successfully" \
    && ls -la public/build




# --------------------------------------------------
# Stage 2: Laravel PHP and Apache
# --------------------------------------------------
FROM php:8.4-apache


ENV COMPOSER_ALLOW_SUPERUSER=1 \
    COMPOSER_MEMORY_LIMIT=-1 \
    COMPOSER_PROCESS_TIMEOUT=2000 \
    APACHE_DOCUMENT_ROOT=/var/www/html/public


RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    unzip \
    zip \
    libzip-dev \
    libpq-dev \
    libicu-dev \
    libonig-dev \
    libxml2-dev \
    libpng-dev \
    libjpeg62-turbo-dev \
    libfreetype6-dev \
    && docker-php-ext-configure gd \
        --with-freetype \
        --with-jpeg \
    && docker-php-ext-install -j"$(nproc)" \
        bcmath \
        gd \
        intl \
        mbstring \
        opcache \
        pcntl \
        pdo_mysql \
        pdo_pgsql \
        sockets \
        zip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*


RUN a2enmod rewrite \
    && sed -ri \
        -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' \
        -e 's!AllowOverride None!AllowOverride All!g' \
        /etc/apache2/sites-available/*.conf \
        /etc/apache2/apache2.conf \
        /etc/apache2/conf-available/*.conf


COPY --from=composer:2 /usr/bin/composer /usr/bin/composer


WORKDIR /var/www/html


COPY composer.json composer.lock ./


RUN composer install \
    --no-dev \
    --prefer-dist \
    --no-interaction \
    --no-progress \
    --optimize-autoloader \
    --no-scripts


# Copy Laravel application
COPY . .


# Copy compiled frontend assets
COPY --from=frontend /app/public/build /var/www/html/public/build


# Verify final manifest location
RUN test -f /var/www/html/public/build/manifest.json \
    && echo "Vite manifest successfully copied" \
    && ls -la /var/www/html/public/build


RUN mkdir -p \
        storage/framework/cache/data \
        storage/framework/sessions \
        storage/framework/views \
        storage/logs \
        bootstrap/cache \
    && composer dump-autoload \
        --no-dev \
        --optimize \
        --no-interaction \
        --no-scripts \
    && chown -R www-data:www-data storage bootstrap/cache \
    && chmod -R 775 storage bootstrap/cache \
    && chmod +x docker/start.sh


EXPOSE 80


CMD ["./docker/start.sh"]


