FROM debian:stretch-backports
ENV DEBIAN_FRONTEND=noninteractive TAG=1.13.3 SOURCE=1.13.3-1~bpo9+1
RUN apt-get -qqy update && apt-get install -qq packaging-dev debian-keyring devscripts equivs perl

WORKDIR /opt/
RUN dget -x "http://http.debian.net/debian/pool/main/n/nginx/nginx_${SOURCE}.dsc"
WORKDIR /opt/nginx-$TAG
RUN mk-build-deps --install --remove --tool "apt-get -qq"

WORKDIR /opt/nginx-$TAG/debian/modules

# VTS
RUN git clone --depth=1 git://github.com/vozlt/nginx-module-vts.git && cd nginx-module-vts && \
    echo 'load_module modules/ngx_http_vhost_traffic_status_module.so;' > /opt/nginx-$TAG/debian/libnginx-mod.conf/mod-http-vhost-traffic-status.conf && \
    sed -i "s|--with-stream_ssl_module|--with-stream_ssl_module --add-dynamic-module=\$(MODULESDIR)/nginx-module-vts|" /opt/nginx-$TAG/debian/rules && \
    sed -i "s|http-xslt-filter|http-xslt-filter http-vhost-traffic-status|" /opt/nginx-$TAG/debian/rules
ADD packages/package.nginx /opt/nginx-$TAG/debian/libnginx-mod-http-vhost-traffic-status.nginx
RUN printf '\n\
Package: libnginx-mod-http-vhost-traffic-status\n\
Architecture: any\n\
Depends: ${misc:Depends}, ${shlibs:Depends}\n\
Description: VTS support for Nginx\n'\
>> /opt/nginx-$TAG/debian/control

# build and package
WORKDIR /opt/nginx-$TAG
RUN dpkg-buildpackage -us -uc

RUN rm ../*-dbgsym*.deb && tar -czvf /opt/nginx-$TAG.tar /opt/libnginx-mod-http-vhost-traffic-status_*.deb
