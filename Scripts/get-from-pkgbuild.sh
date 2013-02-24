#!/bin/bash

if [ "x$(whoami)" != "xnobody" ]; then
  echo "Not running as nobody."
  exit 1
fi

if [ ! -f "${1}" ]; then
  echo "File not found."
  exit 1
fi

if [ -z "${2}" ]; then
  echo "No variable specified."
  exit 1
fi

source "${1}"
eval "echo \"\${${2}}\""
