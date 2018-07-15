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

# WAF mod Security
RUN apt-get -qq update && apt-get install -qq g++ flex bison curl doxygen libyajl-dev libgeoip-dev libtool dh-autoreconf libcurl4-gnutls-dev libxml2 zlib1g-dev libpcre++-dev libxml2-dev
RUN git clone --depth 1 -b v3/master --single-branch https://github.com/SpiderLabs/ModSecurity /opt/ModSecurity && cd /opt/ModSecurity && \
    git submodule init && git submodule update && \
    ./build.sh && ./configure --prefix=/usr && \
    make && make install
RUN git clone --depth 1 https://github.com/SpiderLabs/ModSecurity-nginx.git nginx_modsecurity && \
    echo 'load_module modules/ngx_http_modsecurity_module.so;' > /opt/nginx-$TAG/debian/libnginx-mod.conf/mod-http-modsecurity.conf && \
    sed -i "s|--with-stream=dynamic|--with-stream=dynamic --add-dynamic-module=\$(MODULESDIR)/nginx_modsecurity|" /opt/nginx-$TAG/debian/rules && \
    sed -i "s|http-image-filter|http-image-filter http-modsecurity|" /opt/nginx-$TAG/debian/rules
ADD packages/package.nginx /opt/nginx-$TAG/debian/libnginx-mod-http-modsecurity.nginx
RUN mkdir -p /opt/nginx-$TAG/usr/lib && \
    cp /usr/lib/libmodsecurity.so.3.0.2 /opt/nginx-$TAG/usr/lib/libmodsecurity.so.3 && \
    echo 'usr/lib/libmodsecurity.so.3' > /opt/nginx-$TAG/debian/libnginx-mod-http-modsecurity.install && \
    echo 'usr/lib/libmodsecurity.so.3' > /opt/nginx-$TAG/debian/source/include-binaries

RUN printf '\n\
Package: libnginx-mod-http-modsecurity\n\
Architecture: any\n\
Depends: ${misc:Depends}, ${shlibs:Depends}\n\
Description: ModSecurity support for Nginx\n'\
>> /opt/nginx-$TAG/debian/control

# build and package
WORKDIR /opt/nginx-$TAG
RUN dpkg-buildpackage -us -uc

RUN rm ../*-dbgsym*.deb && tar -czvf /opt/nginx-$TAG.tar /opt/libnginx-mod-http-modsecurity_*.deb
