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


FROM php:8.4-apache


ENV COMPOSER_ALLOW_SUPERUSER=1 \
    COMPOSER_MEMORY_LIMIT=-1 \
    COMPOSER_PROCESS_TIMEOUT=2000 \
    APACHE_DOCUMENT_ROOT=/var/www/html/public


# Install OS libraries needed for PHP extensions
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


# Enable Apache rewrite and Point DocumentRoot to Laravel public/
RUN a2enmod rewrite \
    && sed -ri \
        -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' \
        -e 's!AllowOverride None!AllowOverride All!g' \
        /etc/apache2/sites-available/*.conf \
        /etc/apache2/apache2.conf \
        /etc/apache2/conf-available/*.conf


# Copy Composer binary
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer


WORKDIR /var/www/html


# Cache Composer dependency layer
COPY composer.json composer.lock ./


# Diagnose platform requirements, then install production dependencies
RUN php -v \
    && php -m \
    && composer install \
        --no-dev \
        --prefer-dist \
        --no-interaction \
        --no-progress \
        --optimize-autoloader \
        --no-scripts


# Copy application source (vendor is excluded via .dockerignore)
COPY . .


# Ensure Laravel writable directories exist
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


RUN chown -R www-data:www-data storage bootstrap/cache \
    && chmod -R 775 storage bootstrap/cache


EXPOSE 80


CMD ["./docker/start.sh"]



