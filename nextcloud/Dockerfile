# Use official Nextcloud FPM image (pulls linux/arm64 natively on Raspberry Pi 5)
FROM nextcloud:fpm

RUN set -ex; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        ffmpeg \
        ghostscript \
        libmagickwand-dev \
        libmagickcore-7.q16-10-extra \
    ; \
    rm -rf /var/lib/apt/lists/*; \
    # Recompile imagick PHP extension natively for ARM64.
    # The official nextcloud:fpm image ships imagick compiled against x86_64 headers
    # which causes SIGSEGV crashes on aarch64 (Raspberry Pi 5). Uninstalling and
    # reinstalling via PECL compiles it against the correct aarch64 libraries.
    pecl uninstall imagick; \
    pecl install imagick; \
    docker-php-ext-enable imagick

# Disable OPcache JIT — PHP 8.x JIT is unstable on ARM64 and causes SIGSEGV
# worker crashes in PHP-FPM. Also frees the 8MB JIT buffer back to the system.
RUN { \
        echo 'opcache.jit=disable'; \
        echo 'opcache.jit_buffer_size=0'; \
    } > /usr/local/etc/php/conf.d/zzz-arm64-jit-disable.ini
