FROM nextcloud

LABEL "Project"="NextCloud Pi"
LABEL "Author"="Javad Ali"

ENV MYSQL_PASSWORD="password"
ENV MYSQL_DATABASE="nextcloud"
ENV MYSQL_USER="admin"
ENV MYSQL_HOST="nextcloud_db"
ENV PHP_MEMORY_LIMIT="4G"
ENV PHP_UPLOAD_LIMIT="10G"
ENV PHP_MAX_EXECUTION_TIME="7200"
ENV PHP_POST_MAX_SIZE="10G"
ENV PHP_MAX_INPUT_TIME="7200"
ENV REDIS_HOST="nextcloud_redis"

COPY nextcloud.ini /usr/local/etc/php/conf.d/nextcloud.ini

ADD config.sh /scripts/config.sh
RUN chmod +x /scripts/config.sh && /scripts/config.sh

COPY supervisord.conf /etc/supervisor/supervisord.conf 
ENV NEXTCLOUD_UPDATE=1
CMD ["/usr/bin/supervisord"]