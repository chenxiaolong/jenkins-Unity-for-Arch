#!/bin/bash

set -x

ARCH_SUPPORTED=('i686' 'x86_64')
CONFIG_FILE=/srv/jenkins/build-in-chroot.conf

ARGS=$(getopt -o c: -l config: -n build-wrapper.sh -- "${@}")

if [ ${?} -ne 0 ]; then
  echo "Failed to parse argument!"
  exit 1
fi

eval set -- "${ARGS}"

while true; do
  case "${1}" in
  -c|--config)
    shift
    CONFIG_FILE="${1}"
    shift
    ;;
  --)
    shift
    break
    ;;
  esac
done

set -e

if [ ! -f "${CONFIG_FILE}" ]; then
  echo "${CONFIG_FILE} does not exist!"
  exit 1
fi

# Clean up old packages from the pacman cache
(
  flock 321 || (echo "Failed to acquire lock on pacman cache!" && exit 1)
  python3 /srv/jenkins/clean-pacman-cache.py
) 321>$(dirname ${0})/cache.lock

source "${CONFIG_FILE}"

ARCH_PACKAGE=$(sudo -u nobody bash -c "source ${1}/PKGBUILD && \
                                       echo \${arch[@]}")

# If we have an architecture-independent package, we need to copy it to all of
# the local repos
if [ "x${ARCH_PACKAGE}" = "xany" ]; then
  /srv/jenkins/build-in-chroot.sh -c ${CONFIG_FILE} -p "${1}" -a ${ARCH_SUPPORTED[0]} -k
  COPY_FROM=${LOCALREPO/@ARCH@/${ARCH_SUPPORTED[0]}}
  # Lock the source repo to make sure nothing is changed while we copy from it
  (
    flock 123 || (echo "Failed to acquire lock on local repo!" && exit 1)
    for arch in ${ARCH_SUPPORTED[@]}; do
      COPY_TO=${LOCALREPO/@ARCH@/${arch}}
      if [ "x${COPY_TO}" = "x${COPY_FROM}" ]; then
        continue
      fi
      mkdir -p ${COPY_TO}/
      (
        flock 234 || (echo "Failed to acquire lock on local repo!" && exit 1)
        rm -f ${COPY_TO}/*.db*
        rm -f ${COPY_TO}/*.files*
        cp ${COPY_FROM}/*-any.pkg.tar.xz ${COPY_TO}/
        repo-add ${COPY_TO}/${REPO}.db.tar.xz ${COPY_TO}/*.pkg.tar.xz
        repo-add -f ${COPY_TO}/${REPO}.files.tar.xz ${COPY_TO}/*.pkg.tar.xz
      ) 234>${COPY_TO}/repo.lock
    done
  ) 123>${COPY_FROM}/repo.lock
else
  for arch in ${ARCH_SUPPORTED[@]}; do
    /srv/jenkins/build-in-chroot.sh -c ${CONFIG_FILE} -p "${1}" -a ${arch} -k
  done
fi
