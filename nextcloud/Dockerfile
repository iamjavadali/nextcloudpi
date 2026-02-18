# Use latest official Nextcloud FPM image
FROM nextcloud:fpm

# Install required tools
RUN apt update && \
    apt install -y ffmpeg imagemagick && \
    apt clean && rm -rf /var/lib/apt/lists/*