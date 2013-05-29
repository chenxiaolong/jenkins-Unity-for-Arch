#!/bin/bash

set -ex

#if [ -d TEMP/ ]; then
#  rm -rf TEMP/
#fi

if [ -f jenkins.PKGBUILD ]; then
  rm jenkins.PKGBUILD
fi

if [ ! -d TEMP/ ]; then
  mkdir TEMP/
fi

cd TEMP/
tar Jxf ../snapshot.tar.xz

cd ${1}

makepkg --nobuild --nodeps --clean

cp PKGBUILD ../../jenkins.PKGBUILD
#cd ../../
#rm -rf TEMP
