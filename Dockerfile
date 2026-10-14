FROM php:8.4-apache

RUN apt-get update && apt-get install -y --no-install-recommends \
        git unzip zlib1g-dev libzip-dev libpng-dev libjpeg62-turbo-dev \
        libfreetype6-dev libicu-dev libwebp-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp \
    && docker-php-ext-install -j"$(nproc)" gd intl pdo_mysql zip opcache \
    && rm -rf /var/lib/apt/lists/*

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Neos serves from Web/ and needs mod_rewrite
RUN a2enmod rewrite headers expires \
    && sed -ri 's!/var/www/html!/var/www/html/Web!g' /etc/apache2/sites-available/000-default.conf \
    && printf '<Directory /var/www/html/Web>\n  AllowOverride All\n  Require all granted\n</Directory>\n' \
       > /etc/apache2/conf-available/neos.conf \
    && a2enconf neos

RUN cp "$PHP_INI_DIR/php.ini-development" "$PHP_INI_DIR/php.ini"
COPY php.ini /usr/local/etc/php/conf.d/zz-neos.ini
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

WORKDIR /var/www/html
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["apache2-foreground"]
