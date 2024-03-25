#!/bin/bash

apt update
# PHP Module bz2
docker-php-ext-install bz2

# PHP Module imap
apt install libc-client-dev libkrb5-dev -y
docker-php-ext-configure imap --with-kerberos --with-imap-ssl 
docker-php-ext-install imap

# PHP Module gmp
apt install libgmp3-dev -y
docker-php-ext-install gmp

# PHP Module smbclient
apt install smbclient libsmbclient-dev -y
pecl install smbclient 
docker-php-ext-enable smbclient

# ffmpeg
apt install ffmpeg -y

# imagemagick SVG support
apt install libmagickcore-6.q16-6-extra -y

# LibreOffice - uncomment below to install LibreOffice.
# apt install libreoffice -y

# CRON via supervisor
apt install supervisor -y
mkdir /var/log/supervisord /var/run/supervisord 

# The following Dockerfile commands are also necessary for a sucessfull cron installation: 
# COPY supervisord.conf /etc/supervisor/supervisord.conf 
# CMD ["/usr/bin/supervisord"]

# https://github.com/nextcloud/docker/tree/master/.examples

apt install sudo -y

# To increase OPcache memeory consumption from 128 to 256
apt install nano -y
# nano /usr/local/etc/php/php.ini-development
# CTRL + w     search for opcache.memory.consumption  then change value from 128 to 256 and save file
# restart nextcloud container.

# File to edit
file_path="/usr/local/etc/php/php.ini-development"

# Value to search for and replace with
search_value=";opcache.memory_consumption=128"
replace_value=";opcache.memory_consumption=256"

# Check if the file exists
if [ ! -f "$file_path" ]; then
    echo "Error: File $file_path does not exist."
    exit 1
fi

# Check if the search value exists in the file
if grep -q "$search_value" "$file_path"; then
    # Replace the search value with the replace value
    sed -i "s/$search_value/$replace_value/" "$file_path"
    echo "Value replaced successfully."
else
    echo "Error: $search_value not found in $file_path"
    exit 1
fi