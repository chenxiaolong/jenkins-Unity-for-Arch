#!/bin/bash

if [ "x$(whoami)" != "xroot" ]; then
  echo "This script must be run as root!"
  exit 1
fi

find /srv/livecds/ -name 'Unity-for-Arch-*.iso' | sort | head -n -3 | xargs rm
