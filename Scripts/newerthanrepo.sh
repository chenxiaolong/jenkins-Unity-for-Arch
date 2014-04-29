#!/bin/bash

ARGS=$(getopt -o c:p:v: -l config:package:version: -n cmprepover.sh -- "${@}")

if [ ${?} -ne 0 ]; then
  echo "Failed to parse arguments!"
  exit 1
fi

eval set -- "${ARGS}"

while true; do
  case "${1}" in
  -c|--config)
    shift
    CONFIG="${1}"
    shift
    ;;
  -p|--package)
    shift
    PACKAGE="${1}"
    shift
    ;;
  -v|--version)
    shift
    VERSION="${1}"
    shift
    ;;
  --)
    shift
    break
    ;;
  esac
done

source "${CONFIG}"

RET=$(python3 /srv/jenkins/cmprepover.py "${LOCALREPO/@ARCH@/\$arch}" "${REPO}" "${PACKAGE}" "${VERSION}")

case "${RET}" in
-1)
    exit 1
    ;;
0)
    exit 1
    ;;
1)
    exit 0
    ;;
*)
    echo "ERROR" >&2
    exit 1
    ;;
esac
