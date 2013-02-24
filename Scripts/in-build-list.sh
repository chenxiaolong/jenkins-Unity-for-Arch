#!/bin/bash

if [ -z "${1}" ]; then
  echo "No argument provided!"
  exit 1
fi

if [ -f changed-packages ]; then
  source changed-packages
  if [ "x$(eval echo "\$build_${1//-/_}")" = "xtrue" ]; then
    echo "${1} is in changed-packages. Triggering build..."
    exit 0
  fi
  echo "${1} is not in changed-packages. Build will not be triggered."
  exit 1
fi
echo "changed-packages not found. No packages to rebuild."
exit 1
