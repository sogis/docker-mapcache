FROM debian:buster

RUN apt-get update && \
    apt-get install --assume-yes --no-install-recommends apache2 libapache2-mod-mapcache mapcache-tools ca-certificates && \
    apt-get clean
RUN mkdir -p /var/run/apache2 && \
    chown --recursive root:www-data /var/log/apache2/ /var/run/apache2 && \
    chmod --recursive g+w /var/log/apache2 /var/run/apache2 && \
    sed -i -e 's/<VirtualHost \*:80>/<VirtualHost *:8080>/' /etc/apache2/sites-available/000-default.conf && \
    sed -i -e 's/Listen 80/Listen 8080/' /etc/apache2/ports.conf

RUN mkdir /mapcache /tiles && \
    chown www-data: /mapcache /tiles
COPY mapcache.xml wmts-seeding-perimeter.gpkg /mapcache/
RUN chown www-data: /mapcache/wmts-seeding-perimeter.gpkg
COPY mapcache.conf /etc/apache2/sites-available/mapcache.conf
RUN a2ensite mapcache

VOLUME ["/tiles"]

EXPOSE 8080

USER www-data

CMD ["/usr/sbin/apachectl", "-DFOREGROUND"]
