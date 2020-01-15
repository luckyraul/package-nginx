#!/bin/sh
set -eu

Info () {
  echo "I: ${*}" >&2
}

Error () {
  echo "E: ${*}" >&2
}

Indent () {
  sed -e 's@^@  @g' "${@}"
}

Info "Starting build of NGINX ${TAG} using travis for ${DEBIAN}"

Info "Using Dockerfile:"
Indent Dockerfile

Info "Building Docker image ${TAG} for ${DEBIAN}"
docker build --tag="${TAG}" --build-arg DTAG="${TAG}" --build-arg SOURCE="${SOURCE}" --build-arg DEPLOYER="${DEPLOYER}" .

id=$(docker create "${TAG}")
docker cp $id:/opt/nginx-$TAG.tar local.tar
docker rm -v $id

Info "Removing Dockerfile"
rm -f Dockerfile

mkdir -p packages
tar -xvf local.tar -C packages

Info "Build result"
ls -lah packages

Info "Build successful"
docker run --rm -ti -v $(pwd)/packages:/root/packages mygento/deployer:v2 ls -lah /root/packages

sudo apt-get -q update && sudo apt-get -qq install python-swiftclient

Info "Starting upload"
swift upload apt-manager packages/*.deb

Info "Upload success"
