FROM ghcr.io/mygento/deployer:v3

ARG DTAG=1.14.2
ARG SOURCE=1.14.2-2+deb10u4

ENV DEBIAN_FRONTEND=noninteractive TAG=${DTAG} SOURCE=${SOURCE}

RUN VER=$(cat /etc/debian_version) && \
    echo "Building Docker image ${DTAG} for ${VER} with source ${SOURCE}"

RUN apt-get -qqy update && apt-get install -qq debhelper packaging-dev debian-keyring devscripts equivs perl

WORKDIR /opt/
RUN dget -x "http://http.debian.net/debian/pool/main/n/nginx/nginx_${SOURCE}.dsc"
WORKDIR /opt/nginx-$TAG
RUN mk-build-deps --install --remove --tool "apt-get -qq"

WORKDIR /opt/nginx-$TAG/debian/modules
