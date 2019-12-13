#!/bin/bash

set -e

docker build \
  --build-arg APT_HTTP_PROXY=${APT_HTTP_PROXY:-DIRECT} \
  -t bvoigt/apt-cacher-ng \
  .

docker stop apt-cacher-ng && docker rm apt-cacher-ng

docker run \
  --name apt-cacher-ng \
  -d \
  -v apt-cacher-ng:/var/cache/apt-cacher-ng \
  -p "3142:3142" \
  --restart unless-stopped \
  bvoigt/apt-cacher-ng
