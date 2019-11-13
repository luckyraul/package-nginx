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

# BROTLI
RUN git clone --depth=1 https://github.com/google/ngx_brotli.git && cd ngx_brotli && \
  git submodule init && git submodule update && \
  rm -fR deps/brotli/tests deps/brotli/research/img deps/brotli/java deps/brotli/docs/brotli-comparison-study-2015-09-22.pdf && \
  echo 'load_module modules/ngx_http_brotli_filter_module.so;' > /opt/nginx-$TAG/debian/libnginx-mod.conf/mod-http-brotli-filter.conf && \
  echo 'load_module modules/ngx_http_brotli_static_module.so;' > /opt/nginx-$TAG/debian/libnginx-mod.conf/mod-http-brotli-static.conf && \
  sed -i "s|--with-stream_ssl_module|--with-stream_ssl_module --add-dynamic-module=\$(MODULESDIR)/ngx_brotli|" /opt/nginx-$TAG/debian/rules && \
  sed -i "s|http-xslt-filter|http-xslt-filter http-brotli-filter http-brotli-static|" /opt/nginx-$TAG/debian/rules
ADD packages/package.nginx /opt/nginx-$TAG/debian/libnginx-mod-http-brotli-filter.nginx
ADD packages/package.nginx /opt/nginx-$TAG/debian/libnginx-mod-http-brotli-static.nginx
RUN printf '\n\
Package: libnginx-mod-http-brotli-filter\n\
Architecture: any\n\
Depends: ${misc:Depends}, ${shlibs:Depends}\n\
Description: brotli compression support for Nginx\n'\
>> /opt/nginx-$TAG/debian/control
RUN printf '\n\
Package: libnginx-mod-http-brotli-static\n\
Architecture: any\n\
Depends: ${misc:Depends}, ${shlibs:Depends}\n\
Description: brotli compression support for Nginx\n'\
>> /opt/nginx-$TAG/debian/control


# build and package
WORKDIR /opt/nginx-$TAG
RUN dpkg-buildpackage -us -uc

RUN rm ../*-dbgsym*.deb && cd /opt/ && tar -czvf /opt/nginx-$TAG.tar -C /opt libnginx-mod-http-brotli-*.deb
