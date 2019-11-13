ARG DEBIAN=buster
FROM debian:${DEBIAN}

ARG TAG=1.14.2
ARG SOURCE=1.14.2-2+deb10u1

ENV DEBIAN_FRONTEND=noninteractive TAG=${TAG} SOURCE=${SOURCE}
RUN apt-get -qqy update && apt-get install -qq packaging-dev debian-keyring devscripts equivs perl

WORKDIR /opt/
RUN dget -x "http://http.debian.net/debian/pool/main/n/nginx/nginx_${SOURCE}.dsc"
WORKDIR /opt/nginx-$TAG
RUN mk-build-deps --install --remove --tool "apt-get -qq"

WORKDIR /opt/nginx-$TAG/debian/modules
