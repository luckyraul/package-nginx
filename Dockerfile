FROM debian:stretch-backports
ENV DEBIAN_FRONTEND=noninteractive TAG=1.13.3 SOURCE=1.13.3-1~bpo9+1 NPS_VERSION=1.13.35.2
RUN apt-get -qqy update && apt-get install -qq packaging-dev debian-keyring devscripts equivs
WORKDIR /opt/
RUN dget -x "http://http.debian.net/debian/pool/main/n/nginx/nginx_${SOURCE}.dsc"
WORKDIR /opt/nginx-$TAG
RUN mk-build-deps --install --remove --tool "apt-get -qq"
RUN dch -l mygento --distribution stretch-backports "Rebuild with Pagespeed, brotli"
RUN ls -lha ../

WORKDIR /opt/nginx-$TAG/debian/modules

RUN apt-get install -qqy mc nano

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
  sed -i "s|--with-stream_ssl_preread_module|--with-stream_ssl_preread_module --add-dynamic-module=\$(MODULESDIR)/ngx_pagespeed|" /opt/nginx-$TAG/debian/rules

# BROTLI
RUN git clone --depth=1 https://github.com/google/ngx_brotli.git && cd ngx_brotli && \
  git submodule init && git submodule update && \
  rm -fR deps/brotli/tests deps/brotli/research/img deps/brotli/java deps/brotli/docs/brotli-comparison-study-2015-09-22.pdf && \
  sed -i "s|--with-stream_ssl_module|--with-stream_ssl_module --add-dynamic-module=\$(MODULESDIR)/ngx_brotli|" /opt/nginx-$TAG/debian/rules

# build
WORKDIR /opt/nginx-$TAG
RUN fakeroot debian/rules binary
# RUN ls -lha ../

# package
RUN dpkg-buildpackage -us -uc

RUN rm ../*-dbgsym*.deb && tar -czvf /opt/nginx-$TAG.tar /opt/libnginx-mod-*.deb /opt/nginx-extras_${SOURCE}mygento1_amd64.deb /opt/nginx-common_${SOURCE}mygento1_all.deb
