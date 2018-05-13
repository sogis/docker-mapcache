FROM ubuntu:bionic
# Based off work by
# Camptocamp "info@camptocamp.com"
MAINTAINER Stefan Ziegler<stefan.ziegler@bd.so.ch>

ENV VERSION 2018-05-13

RUN apt-get update
RUN LC_ALL=C DEBIAN_FRONTEND=noninteractive apt-get install -qqy \
        libgeos-3.6.2 gdal-bin \ 
        apache2 apache2-dev apache2 \
        libapache2-mod-mapcache libmapcache1 libmapcache1-dev mapcache-cgi mapcache-tools && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/partial/* /tmp/* /var/tmp/*

RUN mkdir /mapcache

ADD mapcache.conf /etc/apache2/sites-available/mapcache.conf
ADD mapcache.load /etc/apache2/mods-available/mapcache.load

RUN a2enmod mapcache rewrite && \
    a2dissite 000-default && \
    a2ensite mapcache && \
    a2dismod -f auth_basic authn_file authn_core authz_host authz_user autoindex dir status && \
    rm /etc/apache2/mods-enabled/alias.conf && \
    find /etc/apache2 -type f -exec sed -ri ' \
       s!^(\s*CustomLog)\s+\S+!\1 /proc/self/fd/1!g; \
       s!^(\s*ErrorLog)\s+\S+!\1 /proc/self/fd/2!g; \
       ' '{}' ';'

WORKDIR /mapcache
VOLUME ["/mapcache"]

EXPOSE 80

CMD ["apache2ctl", "-DFOREGROUND"]