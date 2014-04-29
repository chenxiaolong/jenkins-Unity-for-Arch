#!/usr/bin/env python3

import io
import os
import sys
import tarfile
import time

from urllib.request import urlopen
from urllib.error import URLError

try:
    import pyalpm
except:
    print('Please install the pyalpm package')
    sys.exit(1)

class pkginfo:
    def __init__(self, lines):
        self._data = [ x.decode('UTF-8').strip('\n') for x in lines ]

        self.filename = None
        self.name = None
        self.base = None
        self.version = None
        self.desc = None
        self.groups = None
        self.csize = 0
        self.isize = 0
        self.md5sum = None
        self.sha256sum = None
        self.url = None
        self.license = None
        self.arch = None
        self.builddate = 0
        self.packager = None

        self.load()

    def __str__(self):
        ret = \
                'Filename:       %s\n' % str(self.filename) + \
                'Name:           %s\n' % str(self.name) + \
                'Base:           %s\n' % str(self.base) + \
                'Version:        %s\n' % str(self.version) + \
                'Description:    %s\n' % str(self.desc) + \
                'Groups:         %s\n' % str(self.groups) + \
                'Package size:   %d bytes\n' % self.csize + \
                'Installed size: %d bytes\n' % self.isize + \
                'md5sum:         %s\n' % str(self.md5sum) + \
                'sha256sum:      %s\n' % str(self.sha256sum) + \
                'URL:            %s\n' % str(self.url) + \
                'License:        %s\n' % str(self.license) + \
                'Arch:           %s\n' % str(self.arch) + \
                'Build date:     %s\n' % \
                        time.strftime('%c', time.localtime(self.builddate)) + \
                'Packager:       %s\n' % str(self.packager)
        return ret

    def load(self):
        lines = self._data

        i = 0
        while i < len(lines):
            if i == len(lines) - 1:
                break

            line = lines[i]
            nextline = lines[i + 1]

            if line == '%FILENAME%':
                self.filename = nextline
            elif line == '%NAME%':
                self.name = nextline
            elif line == '%BASE%':
                self.base = nextline
            elif line == '%VERSION%':
                self.version = nextline
            elif line == '%DESC%':
                self.desc = nextline
            elif line == '%GROUPS%':
                self.groups = nextline
            elif line == '%CSIZE%':
                self.csize = int(nextline)
            elif line == '%ISIZE%':
                self.isize = int(nextline)
            elif line == '%MD5SUM%':
                self.md5sum = nextline
            elif line == '%SHA512SUM%':
                self.sha512sum = nextline
            elif line == '%URL%':
                self.url = nextline
            elif line == '%LICENSE%':
                self.license = nextline
            elif line == '%ARCH%':
                self.arch = nextline
            elif line == '%BUILDDATE%':
                self.builddate = int(nextline)
            elif line == '%PACKAGER%':
                self.packager = nextline
            else:
                i += 1
                continue

            i += 3


def real_repo_url(repo_url, repo_name):
    arch = os.uname().machine
    url = repo_url.replace('$arch', arch)
    url = url.replace('$repo', repo_name)
    if url[-1] != '/':
        url += '/%s.db' % repo_name
    else:
        url += '%s.db' % repo_name
    return url


if len(sys.argv) < 5:
    print('Usage %s [repo URL] [repo name] [package name] [package version]')
    sys.exit(1)

repo_url = sys.argv[1]
repo_name = sys.argv[2]
pkg_name = sys.argv[3]
pkg_ver = sys.argv[4]

url = real_repo_url(repo_url, repo_name)

if '://' in url:
    try:
        f = urlopen(url)
        db = f.read()
        f.close()
    except URLError as e:
        print('Failed to download database [%s]: %s' % (str(e), url))
else:
    with open(url, 'rb') as f:
        db = f.read()

repo_pkg_ver = None

with io.BytesIO(db) as dbf:
    with tarfile.open(fileobj=dbf) as tar:
        for member in tar:
            if member.isfile() and member.name.endswith('/desc'):
                with tar.extractfile(member) as fd:
                    lines = fd.readlines()
                info = pkginfo(lines)
                if info.name == pkg_name:
                    repo_pkg_ver = info.version

if not repo_pkg_ver:
    print('%s not found in repo' % pkg_name)
    sys.exit(1)

print(pyalpm.vercmp(pkg_ver, repo_pkg_ver))
