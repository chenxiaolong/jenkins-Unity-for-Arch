#!/usr/bin/env python3

import argparse
import os
import pyalpm
import re
import sys

cachedir = "/var/cache/pacman/pkg/"
printonly = False

parser = argparse.ArgumentParser()
parser.formatter_class = argparse.RawDescriptionHelpFormatter
parser.description = """
Remove old versions of packages from a directory
------------------------------------------------
Default directory: /var/cache/pacman/pkg/
"""
parser.add_argument("-d", "--directory",
                    help="Directory containing packages")
parser.add_argument("-n", "--noformatting",
                    help="Do not format output (useful for scripts)",
                    action="store_true")
parser.add_argument("-p", "--print",
                    help="Print files to be deleted (none actually deleted)",
                    action="store_true")
parser.add_argument("-q", "--quiet",
                    help="Don't print anything",
                    action="store_true")

args = parser.parse_args()

if args.directory:
  cachedir = args.directory

class PkgInfo:
  def __init__(self):
    self.pkgver = 0.0
    self.pkgrel = 0

class Package:
  def __init__(self):
    self.pkgname = ""
    self.arch = ""
    self.versions = []

# A 'package' is a list of packages in the cache with a unique name and arch
packages = []
regex = re.compile(r"^(.+)-(.+)-([0-9]+)-(.+)\.pkg\.tar\.xz$")

for i in os.listdir(cachedir):
  # Don't mess with other files
  matches = regex.match(i)
  if os.path.isfile(cachedir + '/' + i) and matches:
    temp_pkgname = matches.group(1)
    temp_pkgver = matches.group(2)
    temp_pkgrel = matches.group(3)
    temp_arch = matches.group(4)

    temp_pkginfo = PkgInfo()
    temp_pkginfo.pkgver = temp_pkgver
    temp_pkginfo.pkgrel = temp_pkgrel

    # If a 'package' already exists, add the package version to its list
    exists = False
    for j in packages:
      if temp_pkgname == j.pkgname and temp_arch == j.arch:
        exists = True
        j.versions.append(temp_pkginfo)
        break

    # Otherwise, create a new 'package'
    if not exists:
      temp_package = Package()
      temp_package.pkgname = temp_pkgname
      temp_package.arch = temp_arch
      temp_package.versions.append(temp_pkginfo)
      packages.append(temp_package)

removing = []

for i in packages:
  counter1 = 0
  while counter1 < len(i.versions):
    counter2 = counter1
    while counter2 < len(i.versions):
      # Use pacman's alpm library to compare and sort the package versions
      if pyalpm.vercmp(
           i.versions[counter1].pkgver + '-' + i.versions[counter1].pkgrel,
           i.versions[counter2].pkgver + '-' + i.versions[counter2].pkgrel) < 0:
        i.versions[counter1], i.versions[counter2] = \
          i.versions[counter2], i.versions[counter1]
      counter2 += 1
    counter1 += 1

  # Don't remove newest version
  del(i.versions[0])
  for j in i.versions:
    removing.append(i.pkgname + '-' +
                    j.pkgver + '-' +
                    j.pkgrel + '-' +
                    i.arch + '.pkg.tar.xz')

if removing:
  # Sort alphabetically to make the output easier to read
  counter1 = 0
  while counter1 < len(removing):
    counter2 = counter1
    while counter2 < len(removing):
      if removing[counter1] > removing[counter2]:
        removing[counter1], removing[counter2] = \
          removing[counter2], removing[counter1]
      counter2 += 1
    counter1 += 1

  if not args.quiet and not args.noformatting:
    print("Removing from " + cachedir + ":")

  for i in removing:
    if not args.quiet:
      if args.noformatting:
        print(i)
      else:
        print(" -> " + i)

    if not args.print:
      os.remove(cachedir + '/' + i)

else:
  print("Nothing to remove from " + cachedir)
