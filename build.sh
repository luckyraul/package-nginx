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

TAG="1.13.3"

Info "Starting build of NGINX ${TAG} using travis"

Info "Using Dockerfile:"
Indent Dockerfile

Info "Building Docker image ${TAG}"
docker build --tag="${TAG}" .

id=$(docker create "${TAG}")
docker cp $id:/opt/nginx-$TAG.tar - > local.tar
docker rm -v $id

Info "Removing Dockerfile"
rm -f Dockerfile

ls -lah .

sudo apt-get install --yes --no-install-recommends autopkgtest autodep8

Info "Build successful"
