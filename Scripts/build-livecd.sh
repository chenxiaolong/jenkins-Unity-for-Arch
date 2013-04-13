#!/bin/bash

if [ "x$(whoami)" != "xroot" ]; then
  echo "This script must be run as root!"
  exit 1
fi

SHA512_CREATE_SCRIPT='5e4f6702332a4df4427c06cc4efa04261acefd48af5862a0d5a638c668aaf2930892eab325c3651ecef49d46926975c6a46ac5e47205abdd831c00c26df145c0'
SHA512_BUILD_SCRIPT='0dab32b9825c8ebf0b63afd5d586de11bc496825bc3c2db70d6061d3db4dcf7b805ebb57e8e08a1edbd09e9752720d4f840b0e936d6c8a4c2aa6158dd8604be8'

if ! echo "${SHA512_CREATE_SCRIPT} create-livecd.sh" | sha512sum -c --status; then
  echo "create-livecd.sh sha512sum does not match!"
  exit 1
fi

if ! echo "${SHA512_BUILD_SCRIPT} unity/build.sh" | sha512sum -c --status; then
  echo "unity/build.sh sha512sum does not match!"
  exit 1
fi

set -ex

cleanup() {
  rm -rf --one-file-system unity/work/ unity/out/ unity/cache/
}

trap "cleanup" SIGINT SIGTERM SIGKILL EXIT

# Copy system cache to local cache
mkdir -p unity/cache/
(
  flock 321 || (echo "Failed to acquire lock on pacman cache!" && exit 1)

  # Clean up old packages from the pacman cache
  python3 /srv/jenkins/clean-pacman-cache.py
) 321>$(dirname ${0})/cache.lock
cp /var/cache/pacman/pkg/*.pkg.tar.xz unity/cache/

# Build LiveCD
./create-livecd.sh

# Copy LiveCD image to appropriate location
mkdir -p /srv/livecds/
ISOFILE=$(ls unity/out/*.iso | tail -n 1)
ISOARCH=$(sed 's/^Unity-for-Arch-[[:digit:]]\+\.[[:digit:]]\+\.[[:digit:]]\+-\(.\+\)\.iso/\1/g' <<< ${ISOFILE})
cp unity/out/${ISOFILE} /srv/livecds/
echo "${ISOFILE}" > /srv/livecds/latest.${ISOARCH}

# Merge local cache back to system cache
(
  flock 321 || (echo "Failed to acquire lock on pacman cache!" && exit 1)

  for i in unity/cache/*.pkg.tar.xz; do
    if [ ! -f /var/cache/pacman/pkg/$(basename ${i}) ]; then
      mv ${i} /var/cache/pacman/pkg/
    fi
  done
  
  # Clean up old packages from the pacman cache
  python3 /srv/jenkins/clean-pacman-cache.py
) 321>$(dirname ${0})/cache.lock
