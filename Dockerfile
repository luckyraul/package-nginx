ARG DEBIAN=buster
FROM debian:${DEBIAN}

ARG DTAG=1.14.2
ARG SOURCE=1.14.2-2+deb10u1

ENV DEBIAN_FRONTEND=noninteractive TAG=${DTAG} SOURCE=${SOURCE}

RUN echo "Building Docker image ${DTAG} for ${DEBIAN} with source ${SOURCE}"

RUN apt-get -qqy update && apt-get install -qq packaging-dev debian-keyring devscripts equivs perl

WORKDIR /opt/
RUN dget -x "http://http.debian.net/debian/pool/main/n/nginx/nginx_${SOURCE}.dsc"
WORKDIR /opt/nginx-$TAG
RUN mk-build-deps --install --remove --tool "apt-get -qq"

WORKDIR /opt/nginx-$TAG/debian/modules


ENV MODS=3.0.3-1

# WAF mod Security
RUN wget http://ftp.debian.org/debian/pool/main/m/modsecurity/libmodsecurity3_${MODS}_amd64.deb -O /opt/libmodsecurity3_${MODS}_amd64.deb && \
    wget http://ftp.debian.org/debian/pool/main/m/modsecurity/libmodsecurity-dev_${MODS}_amd64.deb -O /opt/libmodsecurity-dev_${MODS}_amd64.deb && \
    apt-get install -qqy libfuzzy2 liblua5.3-0 libmaxminddb0 libyajl2 && \
    dpkg -i /opt/libmodsecurity3_${MODS}_amd64.deb && \
    dpkg -i /opt/libmodsecurity-dev_${MODS}_amd64.deb

RUN git clone --depth 1 https://github.com/SpiderLabs/ModSecurity-nginx.git nginx_modsecurity && \
    echo 'load_module modules/ngx_http_modsecurity_module.so;' > /opt/nginx-$TAG/debian/libnginx-mod.conf/mod-http-modsecurity.conf && \
    sed -i "s|--with-stream=dynamic|--with-stream=dynamic --add-dynamic-module=\$(MODULESDIR)/nginx_modsecurity|" /opt/nginx-$TAG/debian/rules && \
    sed -i "s|http-image-filter|http-image-filter http-modsecurity|" /opt/nginx-$TAG/debian/rules

RUN mkdir -p /opt/nginx-$TAG/etc/nginx/modsec && \
    wget https://raw.githubusercontent.com/SpiderLabs/ModSecurity/v3/master/modsecurity.conf-recommended -O /opt/nginx-$TAG/etc/nginx/modsec/modsecurity.conf && \
    sed -i 's/SecRuleEngine DetectionOnly/SecRuleEngine On/' /opt/nginx-$TAG/etc/nginx/modsec/modsecurity.conf && \
    wget https://raw.githubusercontent.com/SpiderLabs/ModSecurity/v3/master/unicode.mapping -O /opt/nginx-$TAG/etc/nginx/modsec/unicode.mapping && \
    echo 'etc/nginx/modsec/modsecurity.conf' > /opt/nginx-$TAG/debian/libnginx-mod-http-modsecurity.install && \
    echo 'etc/nginx/modsec/unicode.mapping' >> /opt/nginx-$TAG/debian/libnginx-mod-http-modsecurity.install

ADD packages/package.nginx /opt/nginx-$TAG/debian/libnginx-mod-http-modsecurity.nginx

RUN printf '\n\
Package: libnginx-mod-http-modsecurity\n\
Architecture: any\n\
Depends: libmodsecurity3, ${misc:Depends}, ${shlibs:Depends}\n\
Description: ModSecurity support for Nginx\n'\
>> /opt/nginx-$TAG/debian/control

# build and package
WORKDIR /opt/nginx-$TAG
RUN dpkg-buildpackage -b -us -uc

RUN rm ../*-dbgsym*.deb && cd /opt/ && tar -czvf /opt/nginx-$TAG.tar -C /opt libnginx-mod-http-modsecurity_*.deb libmodsecurity3_${MODS}_amd64.deb
