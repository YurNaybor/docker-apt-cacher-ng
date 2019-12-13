#!/bin/bash

set -e

chmod 777 /var/cache/apt-cacher-ng

exec "$@"
