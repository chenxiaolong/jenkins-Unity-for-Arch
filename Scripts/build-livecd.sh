#!/bin/bash

if [ "x$(whoami)" != "xroot" ]; then
  echo "This script must be run as root!"
  exit 1
fi

SHA512_CREATE_SCRIPT='5e4f6702332a4df4427c06cc4efa04261acefd48af5862a0d5a638c668aaf2930892eab325c3651ecef49d46926975c6a46ac5e47205abdd831c00c26df145c0'
SHA512_BUILD_SCRIPT='7db9592d7c973275a5cebc264d3c9de60718ee243fbf47fd830bac66c1b9e11e378ffdd984ee7810390931fef229d4c273a92d09f0d7d1f817afb2be30815d27'
ARCH_SUPPORTED=('i686' 'x86_64')
ARCH=$(uname -m)

if [ ! -z "${1}" ]; then
  ARCH=${1}
fi

SUPPORTED=false
for i in ${ARCH_SUPPORTED[@]}; do
  if [ "x${i}" == "x${ARCH}" ]; then
    SUPPORTED=true
    break
  fi
done
if [ "x${SUPPORTED}" != "xtrue" ]; then
  echo "Unsupported architecture ${ARCH}!"
  exit 1
fi

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

  set +x
  echo "Copying system pacman cache to local cache..."
  cp /var/cache/pacman/pkg/*.pkg.tar.xz unity/cache/
  set -x
) 321>$(dirname ${0})/cache.lock

# Build LiveCD
setarch ${ARCH} ./create-livecd.sh

# Copy LiveCD image to appropriate location
mkdir -p /srv/livecds/
ISOFILE=$(ls unity/out/*.iso | tail -n 1)
ISOFILE=$(basename ${ISOFILE})
ISOARCH=$(sed 's/^Unity-for-Arch-[[:digit:]]\+\.[[:digit:]]\+\.[[:digit:]]\+-\(.\+\)\.iso/\1/g' <<< ${ISOFILE})

COUNTER=1
NEWISOFILE=${ISOFILE}
while [ -f /srv/livecds/${NEWISOFILE} ]; do
  echo "${NEWISOFILE} already exists. Increasing release number..."
  let COUNTER++
  NEWISOFILE=$(sed -n -r "s/^(Unity-for-Arch-[[:digit:]]+\.[[:digit:]]+\.[[:digit:]]+)(-Release[[:digit:]]+)?-(.+\.iso)$/\1-Release${COUNTER}-\3/p" <<< ${NEWISOFILE})
  if [ "${COUNTER}" -eq 10 ]; then
    echo "\${COUNTER} is at 10. Something is clearly wrong!"
    exit 1
  fi
done

cp unity/out/${ISOFILE} /srv/livecds/${NEWISOFILE}
echo "${NEWISOFILE}" > /srv/livecds/latest.${ISOARCH}

# Merge local cache back to system cache
(
  flock 321 || (echo "Failed to acquire lock on pacman cache!" && exit 1)

  set +x
  echo "Merging local pacman cache to system cache..."
  for i in unity/cache/*.pkg.tar.xz; do
    if [ ! -f /var/cache/pacman/pkg/$(basename ${i}) ]; then
      mv ${i} /var/cache/pacman/pkg/
    fi
  done
  set -x
  
  # Clean up old packages from the pacman cache
  python3 /srv/jenkins/clean-pacman-cache.py
) 321>$(dirname ${0})/cache.lock
