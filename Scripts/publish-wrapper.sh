#!/bin/bash

if [ "x$(whoami)" != "xroot" ]; then
  echo "This script must be run as root!"
  exit 1
fi

set -x

CONFIG_BUILD=/srv/jenkins/build-in-chroot.conf
CONFIG_PUBLISH=/srv/jenkins/publish-wrapper.conf

ARGS=$(getopt -o c:p: -l buildconfig:publishconfig: -n publish-wrapper.sh -- "${@}")

if [ ${?} -ne 0 ]; then
  echo "Failed to parse arguments!"
  exit 1
fi

eval set -- "${ARGS}"

while true; do
  case "${1}" in
  -c|--buildconfig)
    shift
    CONFIG_BUILD="${1}"
    shift
    ;;
  -p|--publishconfig)
    shift
    CONFIG_PUBLISH="${1}"
    shift
    ;;
  --)
    shift
    break
    ;;
  esac
done

set -e

if [ ! -f "${CONFIG_BUILD}" ]; then
  echo "${CONFIG_BUILD} does not exist!"
  exit 1
fi

if [ ! -f "${CONFIG_PUBLISH}" ]; then
  echo "${CONFIG_PUBLISH} does not exist!"
  exit 1
fi

source "${CONFIG_BUILD}"
source "${CONFIG_PUBLISH}"

ARCH_SUPPORTED=('i686' 'x86_64')

for arch in ${ARCH_SUPPORTED[@]}; do
  REAL_LOCALREPO=${LOCALREPO/@ARCH@/${arch}}
  REAL_REMOTEREPO=${REMOTEREPO/@ARCH@/${arch}}
  if [ ! -d ${REAL_REMOTEREPO} ]; then
    # "|| true" to ignore potential threading issue. No matter what, the
    # directory will be created anyway.
    sudo -u jenkins mkdir -p ${REAL_REMOTEREPO} || true
  fi
  # Must use the same lock as build-in-chroot.sh, so no files are overwritten
  # while the repo is being copied.
  (
    flock 123 || (echo "Failed to acquire lock on local repo!" && exit 1)
    chown -R jenkins:jenkins ${REAL_LOCALREPO}
    sudo -u jenkins python3 /srv/jenkins/publish-repo.py \
                            ${REAL_LOCALREPO} ${REAL_REMOTEREPO} ${REPO}
    #python3 /srv/jenkins/publish-repo.py \
    #        ${REAL_LOCALREPO} ${REAL_REMOTEREPO} ${REPO}
    #chown -R jenkins:jenkins ${REAL_REMOTEREPO}
  ) 123>${REAL_LOCALREPO}/repo.lock
done
