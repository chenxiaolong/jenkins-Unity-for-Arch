#!/bin/bash

if [ "x$(whoami)" != "xroot" ]; then
  echo "This script must be run as root!"
  exit 1
fi

if [ -z "${1}" ]; then
  echo "No argument provided!"
  exit 1
fi

if [ ! -f "unity/out/${1}" ]; then
  echo "unity/out/${1} does not exist!"
  exit 1
fi

LIVECD_DATE=$(sed 's/^Unity-for-Arch-\([[:digit:]]\+\)\.\([[:digit:]]\+\)\.\([[:digit:]]\+\)-.\+\.iso/\1-\2-\3/g' <<< ${1})

rsync -e ssh -avP unity/out/${1} chenxiaolong@frs.sourceforge.net:/home/frs/project/unity-for-arch/${LIVECD_DATE}/
