# syntax=docker/dockerfile:1.7
# =============================================================================
# Axon DSS — image backend Laravel (php-fpm)
# Peran: Infrastructure/Platform Engineer.
#
# Catatan penting: image ini TIDAK mengubah kode aplikasi milik Developer.
# Perubahan yang ada di sini murni pembungkusan (build & runtime) — sesuai
# batasan Tugas 4 role Infra: "tidak memodifikasi kode aplikasi".
#
# Prinsip hardening yang diterapkan (Tugas 2):
#   1. Base image minimal (alpine) dan versinya di-pin.
#   2. Dependensi dipasang di stage terpisah, sehingga composer + toolchain
#      build tidak ikut ke image akhir (memperkecil attack surface).
#   3. Proses berjalan sebagai non-root (www-data)  -> T-10, Gate 4.
#   4. Tidak ada secret maupun mode debug yang menyala di dalam image
#      -> T-06, T-07 (APP_DEBUG diatur lewat environment, bukan dibekukan
#      di dalam image).
#
# Build context: folder docs/  (lihat docker-compose.yml -> build.context: ..)
# =============================================================================

# --- Stage 1: pasang dependensi PHP dari composer.lock ------------------------
# composer.lock di-commit oleh Developer, sehingga versi dependensi bersifat
# deterministik dan bisa dipindai (SCA) maupun dijadikan bahan SBOM.
FROM composer:2 AS vendor
WORKDIR /build
COPY Dev/axon-devsecops-dss/app/backend/composer.json \
     Dev/axon-devsecops-dss/app/backend/composer.lock ./
RUN composer install \
        --no-dev \
        --no-interaction \
        --no-progress \
        --prefer-dist \
        --optimize-autoloader \
        --no-scripts

# --- Stage 2: runtime --------------------------------------------------------
FROM php:8.3-fpm-alpine

# oniguruma = dependensi runtime mbstring (wajib bagi Laravel: ext-mbstring).
# Paket build dihapus lagi pada layer yang sama agar tidak menambah CVE.
RUN apk add --no-cache oniguruma \
    && apk add --no-cache --virtual .build-deps $PHPIZE_DEPS oniguruma-dev \
    && docker-php-ext-install -j"$(nproc)" mbstring pdo_mysql opcache \
    && apk del --no-network .build-deps

# Konfigurasi PHP & php-fpm hasil hardening (expose_php=Off, display_errors=Off)
COPY Infra/docker/app/php.ini /usr/local/etc/php/conf.d/99-axon.ini
COPY Infra/docker/app/zz-axon-fpm.conf /usr/local/etc/php-fpm.d/zz-axon-fpm.conf

WORKDIR /var/www/html

# Kode aplikasi milik Developer (disalin apa adanya, tidak dimodifikasi)
COPY Dev/axon-devsecops-dss/app/backend/ /var/www/html/
COPY --from=vendor /build/vendor/ /var/www/html/vendor/

COPY Infra/docker/app/entrypoint.sh /usr/local/bin/entrypoint.sh

# Direktori runtime dibuat ulang secara eksplisit karena .dockerignore
# membuang berkas .gitignore di dalamnya, lalu di-own ke www-data.
# `rm -f .env` = jaring pengaman agar tidak ada kredensial yang tertinggal
# di layer image (T-06).
RUN chmod +x /usr/local/bin/entrypoint.sh \
    && mkdir -p storage/framework/cache storage/framework/sessions \
                storage/framework/views storage/logs bootstrap/cache \
    && chown -R www-data:www-data storage bootstrap/cache \
    && rm -f .env

# Least privilege: proses tidak berjalan sebagai root (Gate 4 / T-10)
USER www-data

EXPOSE 9000
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["php-fpm", "-F"]
