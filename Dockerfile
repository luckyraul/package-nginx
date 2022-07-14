FROM debian:{IMAGE}

ARG DTAG=1.14.2
ARG SOURCE=1.14.2-2+deb10u4

ENV DEBIAN_FRONTEND=noninteractive TAG=${DTAG} SOURCE=${SOURCE}

RUN VER=$(cat /etc/debian_version) && \
    echo "Building Docker image ${DTAG} for ${VER} with source ${SOURCE}"
RUN find /etc/apt/sources.list* -type f -exec sed -i 'p; s/^deb /deb-src /' '{}' +

RUN apt-get -qqy update && apt-get install -qq debhelper packaging-dev debian-keyring devscripts equivs perl

WORKDIR /opt/
RUN dget -xu "http://http.debian.net/debian/pool/main/n/nginx/nginx_${SOURCE}.dsc"
RUN sudo apt build-dep nginx -y

WORKDIR /opt/nginx-$TAG/debian/modules
