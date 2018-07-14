FROM debian:stretch-backports
ENV DEBIAN_FRONTEND=noninteractive TAG=1.13.3 SOURCE=1.13.3-1~bpo9+1 NPS_VERSION=1.13.35.2
RUN apt-get -qqy update && apt-get install -qq packaging-dev debian-keyring devscripts equivs perl
WORKDIR /opt/
RUN dget -x "http://http.debian.net/debian/pool/main/n/nginx/nginx_${SOURCE}.dsc"
WORKDIR /opt/nginx-$TAG
RUN mk-build-deps --install --remove --tool "apt-get -qq"
RUN dch -l mygento --distribution stretch-backports "Rebuild with Pagespeed, brotli, Mod Security"
RUN ls -lha ../

WORKDIR /opt/nginx-$TAG/debian/modules

# RUN apt-get install -qqy mc nano

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


# PAGESPEED
RUN apt-get -qqy update && apt-get install -qqy build-essential zlib1g-dev libpcre3 libpcre3-dev unzip uuid-dev
RUN wget https://github.com/apache/incubator-pagespeed-ngx/archive/v${NPS_VERSION}-stable.zip && \
  unzip v${NPS_VERSION}-stable.zip && \
  nps_dir=$(find . -name "*pagespeed-ngx-${NPS_VERSION}-stable" -type d) && \
  mv "$nps_dir" ngx_pagespeed && \
  rm v${NPS_VERSION}-stable.zip && \
  cd ngx_pagespeed && \
  psol_url=https://dl.google.com/dl/page-speed/psol/${NPS_VERSION}-x64.tar.gz && \
  wget ${psol_url} && \
  tar -xzf $(basename ${psol_url}) && \
  rm $(basename ${psol_url}) && \
  rm psol/lib/Release/linux/x64/pagespeed_js_minify && \
  echo 'load_module modules/ngx_pagespeed.so;' > /opt/nginx-$TAG/debian/libnginx-mod.conf/mod-pagespeed.conf && \
  sed -i "s|--with-stream_ssl_preread_module|--with-stream_ssl_preread_module --add-dynamic-module=\$(MODULESDIR)/ngx_pagespeed|" /opt/nginx-$TAG/debian/rules && \
  sed -i "s|http-subs-filter|http-subs-filter pagespeed|" /opt/nginx-$TAG/debian/rules
ADD packages/pagespeed.nginx /opt/nginx-$TAG/debian/libnginx-mod-pagespeed.nginx
RUN printf '\n\
Package: libnginx-mod-pagespeed\n\
Architecture: any\n\
Depends: ${misc:Depends}, ${shlibs:Depends}\n\
Description: Pagespeed for Nginx\n'\
>> /opt/nginx-$TAG/debian/control


# WAF mod Security
RUN apt-get -qq update && apt-get install -qq libcurl4-gnutls-dev
RUN git clone --depth 1 -b v3/master --single-branch https://github.com/SpiderLabs/ModSecurity ModSecurity && cd ModSecurity && \
    git submodule init && git submodule update && \
    ./build.sh && ./configure && \
    make && make install
RUN mv /usr/local/modsecurity/lib/libmodsecurity.so.3.0.2 /usr/lib/libmodsecurity.so.3.0.2 && \
    rm /usr/local/modsecurity/lib/libmodsecurity.so && \
    rm /usr/local/modsecurity/lib/libmodsecurity.so.3 && \
    ln -s /usr/lib/libmodsecurity.so.3.0.2 /usr/lib/libmodsecurity.so.3 && \
    ln -s /usr/lib/libmodsecurity.so.3.0.2 /usr/lib/libmodsecurity.so && \
    rm -fR ModSecurity/examples ModSecurity/others ModSecurity/test ModSecurity/tools ModSecurity/doc ModSecurity/src/.libs/libmodsecurity.so.3.0.2 ModSecurity/src/.libs/libmodsecurity.so.3
RUN git clone --depth 1 https://github.com/SpiderLabs/ModSecurity-nginx.git nginx_modsecurity && \
    echo 'load_module modules/ngx_http_modsecurity_module.so;' > /opt/nginx-$TAG/debian/libnginx-mod.conf/mod-http-modsecurity.conf && \
    sed -i "s|--with-stream=dynamic|--with-stream=dynamic --add-dynamic-module=\$(MODULESDIR)/nginx_modsecurity|" /opt/nginx-$TAG/debian/rules && \
    sed -i "s|http-image-filter|http-image-filter http-modsecurity|" /opt/nginx-$TAG/debian/rules
ADD packages/package.nginx /opt/nginx-$TAG/debian/libnginx-mod-http-modsecurity.nginx
RUN echo 'debian/modules/ModSecurity/src/.libs/libmodsecurity.so /usr/lib' > /opt/nginx-$TAG/debian/libnginx-mod-http-modsecurity.install # && \
    #echo 'debian/modules/ModSecurity/src/.libs/libmodsecurity.so.3 /usr/lib' >> /opt/nginx-$TAG/debian/libnginx-mod-http-modsecurity.install && \
    #echo 'debian/modules/ModSecurity/src/.libs/libmodsecurity.so.3.0.2 /usr/lib' >> /opt/nginx-$TAG/debian/libnginx-mod-http-modsecurity.install
RUN printf '\n\
Package: libnginx-mod-http-modsecurity\n\
Architecture: any\n\
Depends: ${misc:Depends}, ${shlibs:Depends}\n\
Description: ModSecurity support for Nginx\n'\
>> /opt/nginx-$TAG/debian/control

# build and package
WORKDIR /opt/nginx-$TAG
RUN dpkg-buildpackage -us -uc

RUN rm ../*-dbgsym*.deb && tar -czvf /opt/nginx-$TAG.tar /opt/libnginx-mod-*.deb /opt/nginx-extras_${SOURCE}mygento1_amd64.deb /opt/nginx-common_${SOURCE}mygento1_all.deb
