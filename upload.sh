#!/bin/sh

docker run --rm -e SERVICE=$SERVICE -e REALM=$REALM -e REALM_LOGIN=$REALM_LOGIN -e REALM_PASS=$REALM_PASS -v `pwd`:`pwd` -w `pwd` ghcr.io/mygento/deployer:v3 upload_package upload public_apt packages/*.deb
