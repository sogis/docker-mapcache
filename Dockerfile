# QGIS Server 2.18 and MapCache 1.6.1 with Apache FCGI

FROM phusion/baseimage:0.10.1

# Based off work by Sourcepole 
MAINTAINER Stefan Ziegler

ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8

# TODO: CHANGE BACK to upgrade!!!!!!!!
#RUN apt-get update && apt-get upgrade -y
RUN apt-get update 

# Install Apache FCGI
RUN apt-get update && apt-get install -y apache2 libapache2-mod-fcgid

# Install QGIS Server and MapCache
#RUN echo "deb http://qgis.org/debian-ltr xenial main" > /etc/apt/sources.list.d/qgis.org-debian.list
#RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-key CAEB3DC3BDF7FB45
RUN apt-get install -qqy software-properties-common --no-install-recommends  && \
    apt-add-repository -y ppa:ubuntugis/ubuntugis-unstable && \
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 314DF160    
RUN apt-get update && apt-get install -y libgeos-3.5.1 gdal-bin libapache2-mod-mapcache libmapcache1 libmapcache1-dev mapcache-cgi mapcache-tools

# Enable apache modules
RUN a2enmod rewrite headers mapcache

# MapCache configuration 
RUN mkdir /mapcache
COPY mapcache.xml /mapcache/mapcache.xml
COPY wmts-seeding-perimeter.gpkg /mapcache/
COPY mapcache.conf /etc/apache2/sites-available/mapcache.conf
RUN a2dissite 000-default
RUN a2ensite mapcache

# Install apache2 run script
RUN mkdir /etc/service/apache2
ADD apache2-run.sh /etc/service/apache2/run
RUN chmod +x /etc/service/apache2/run

# Docker log file
RUN mkdir /etc/service/dockerlog
ADD dockerlog-run.sh /etc/service/dockerlog/run
RUN chmod +x /etc/service/dockerlog/run

# Directory for tiles
RUN mkdir /tiles
VOLUME ["/tiles"]

EXPOSE 80

# Use baseimage-docker's init system.
CMD ["/sbin/my_init"]

# Clean up downloaded packages
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*