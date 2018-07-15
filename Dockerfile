FROM debian:stretch-backports
ENV DEBIAN_FRONTEND=noninteractive TAG=1.13.3 SOURCE=1.13.3-1~bpo9+1 NPS_VERSION=1.13.35.2
RUN apt-get -qqy update && apt-get install -qq packaging-dev debian-keyring devscripts equivs perl

WORKDIR /opt/
RUN dget -x "http://http.debian.net/debian/pool/main/n/nginx/nginx_${SOURCE}.dsc"
WORKDIR /opt/nginx-$TAG
RUN mk-build-deps --install --remove --tool "apt-get -qq"
#RUN dch -l mygento --distribution stretch-backports "Rebuild with Pagespeed, brotli, Mod Security"

WORKDIR /opt/nginx-$TAG/debian/modules
# RUN apt-get install -qqy mc nano
