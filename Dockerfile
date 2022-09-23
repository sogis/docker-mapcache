FROM debian:bookworm

RUN apt-get update && \
    apt-get install --assume-yes --no-install-recommends apache2 libapache2-mod-mapcache mapcache-tools ca-certificates rsync && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Configuration for running Apache as non-root user
RUN chown --recursive root:root /var/log/apache2 /var/run/apache2 && \
    chmod --recursive g+w /var/log/apache2 /var/run/apache2 && \
    sed -i -e 's/Listen 80/Listen 8080/' /etc/apache2/ports.conf
# Truncate Apache access logs after a certain time using rotatelogs, and send error messages to standard output
RUN sed -i -E \
    -e "s/^(CustomLog) (\S*) (\S*)/\1 \"|\/bin\/cat\" \3 \"expr=osenv('APACHE_ACCESS_LOG_ENABLED') == 'true'\"/" \
    -e "3 i ErrorLog \"|\/bin\/cat\"" \
    /etc/apache2/conf-available/other-vhosts-access-log.conf

# Configure and enable MapCache
RUN mkdir /mapcache /tiles && \
    chmod g+w /mapcache /tiles
COPY wmts-seeding-perimeter.gpkg setup_configfile.sh mapcache.xml /mapcache/
RUN chmod g+w /mapcache/wmts-seeding-perimeter.gpkg /mapcache/mapcache.xml && \
    chmod g-w+x /mapcache/setup_configfile.sh
COPY mapcache.conf /etc/apache2/sites-available/mapcache.conf
RUN a2ensite mapcache

VOLUME ["/tiles"]

EXPOSE 8080

USER 1001

ENTRYPOINT ["/mapcache/setup_configfile.sh"]

CMD ["/usr/sbin/apache2ctl", "-D", "FOREGROUND"]
