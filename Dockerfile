# syntax=docker/dockerfile:1
FROM php:8.5-fpm-alpine AS base

RUN apk add --no-cache \
    libpq \
    icu-libs \
    libzip \
    && apk add --no-cache --virtual .build-deps \
    $PHPIZE_DEPS \
    libpq-dev \
    icu-dev \
    libzip-dev \
    && docker-php-ext-install -j"$(nproc)" \
    pdo_pgsql \
    pgsql \
    intl \
    bcmath \
    zip \
    opcache \
    && apk del --no-network .build-deps \
    && rm -rf /var/cache/apk/*

FROM base AS vendor

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer
WORKDIR /app
COPY composer.json composer.lock ./
RUN --mount=type=cache,target=/tmp/composer-cache \
    COMPOSER_CACHE_DIR=/tmp/composer-cache \
    composer install --no-dev --no-scripts --no-interaction --prefer-dist --optimize-autoloader

FROM base AS production

RUN apk add --no-cache nginx supervisor
RUN sed -i 's/^listen = .*/listen = 127.0.0.1:9000/' /usr/local/etc/php-fpm.d/www.conf

COPY <<'PHPINI' /usr/local/etc/php/conf.d/zz-app.ini
memory_limit = 256M
upload_max_filesize = 64M
post_max_size = 64M
max_execution_time = 60
expose_php = Off
opcache.enable = 1
opcache.enable_cli = 0
opcache.memory_consumption = 128
opcache.validate_timestamps = 0
PHPINI

RUN rm -f /etc/nginx/http.d/default.conf
COPY <<'NGINX' /etc/nginx/http.d/default.conf
server {
    listen 80;
    server_name _;
    root /app/public;
    index index.php;
    client_max_body_size 64M;
    server_tokens off;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    location / { try_files $uri $uri/ /index.php?$query_string; }
    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; }
    error_page 404 /index.php;
    location ~ ^/index\.php(/|$) {
        fastcgi_pass 127.0.0.1:9000;
        fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
        fastcgi_param DOCUMENT_ROOT $realpath_root;
        include fastcgi_params;
        internal;
    }
    location ~ \.php$ { return 404; }
    location ~ /\.(?!well-known) { deny all; }
}
NGINX

COPY <<'SUPERVISOR' /etc/supervisord.conf
[supervisord]
nodaemon=true
logfile=/dev/stdout
logfile_maxbytes=0
user=root
[program:php-fpm]
command=php-fpm --nodaemonize
autostart=true
autorestart=true
stdout_logfile=/dev/stdout
stdout_logfile_maxbytes=0
[program:nginx]
command=nginx -g "daemon off;"
autostart=true
autorestart=true
stdout_logfile=/dev/stdout
stdout_logfile_maxbytes=0
SUPERVISOR

WORKDIR /app
COPY . .
COPY --from=vendor /app/vendor ./vendor
RUN mkdir -p storage/app/public storage/framework/{cache/data,sessions,testing,views} storage/logs bootstrap/cache \
    && chown -R www-data:www-data storage bootstrap/cache && chmod -R 775 storage bootstrap/cache

ENV LOG_CHANNEL=stderr APP_ENV=production APP_DEBUG=false
EXPOSE 80
HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
    CMD wget --quiet --tries=1 --spider http://127.0.0.1/up || exit 1

COPY <<'ENTRYPOINT' /entrypoint.sh
#!/bin/sh
set -e
php artisan package:discover --ansi
if [ "${RUN_MIGRATIONS}" = "true" ]; then
    php artisan migrate --force
fi
php artisan config:cache
php artisan route:cache
php artisan view:cache
exec /usr/bin/supervisord -c /etc/supervisord.conf
ENTRYPOINT
RUN chmod +x /entrypoint.sh
CMD ["/entrypoint.sh"]
