#!/bin/bash

if [ "x$(whoami)" != "xroot" ]; then
  echo "This script must be run as root!"
  exit 1
fi

if [ -z "${1}" ]; then
  echo "No argument provided!"
  exit 1
fi

FILE=/srv/livecds/$(cat /srv/livecds/latest.${1})

if [ ! -f "${FILE}" ]; then
  echo "${FILE} does not exist!"
  exit 1
fi

LIVECD_DATE=$(sed 's/^Unity-for-Arch-\([[:digit:]]\+\)\.\([[:digit:]]\+\)\.\([[:digit:]]\+\)-.\+\.iso/\1-\2-\3/g' <<< $(basename ${FILE}))

rsync -e ssh -avP ${FILE} chenxiaolong@frs.sourceforge.net:/home/frs/project/unity-for-arch/${LIVECD_DATE}/
