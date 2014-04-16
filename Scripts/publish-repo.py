#!/usr/bin/python3

# argv[1] - Local repository
# argv[2] - Remote repository
# argv[3] - Repository name

import os
import shutil
import sys
import tarfile

if len(sys.argv) < 4:
  print("Not enough arguments!")
  sys.exit(1)

repo = sys.argv[3]
repo_remote = sys.argv[2]
repo_local = sys.argv[1]

if not os.path.exists(repo_remote):
  print("Remote repo " + repo_remote + " does not exist!")
  sys.exit(1)

if not os.path.exists(repo_local):
  print("Local repo " + repo_local + " does not exist!")
  sys.exit(1)

def get_pkgs_from_db(repo_path, repo_name):
  packages = []

  repo_db = tarfile.open(repo_path + "/" + repo_name + ".db", 'r')

  # Get packages in the repo's database
  for member in repo_db:
    if member.isfile() and member.name.endswith('/desc'):
      fd = repo_db.extractfile(member)
      content = fd.readlines()
      for index, line in enumerate(content):
        if line.decode('UTF-8') == '%FILENAME%\n':
          packages.append(content[index + 1].decode('UTF-8').strip('\n'))
          break

  repo_db.close()

  return packages

def get_pkgs_from_dir(repo_path):
  package_files = []

  for i in os.listdir(repo_path):
    if os.path.isfile(repo_path + "/" + i) and i.endswith(".pkg.tar.xz"):
      package_files.append(i)

  return package_files

def check_if_pkgs_exist(repo_path, repo_name):
  error = False
  db_pkgs = get_pkgs_from_db(repo_path, repo_name)
  dir_pkgs = get_pkgs_from_dir(repo_path)
  package_list = []

  for i in db_pkgs:
    found = False
    for j in dir_pkgs:
      if i == j:
        package_list.append(j)
        found = True
        break;
    if not found:
      print("Missing package: " + i)
      error = True

  if error:
    sys.exit(1)

  return package_list

def remove_extra_pkgs(repo_path, repo_name):
  db_pkgs = get_pkgs_from_db(repo_path, repo_name)
  package_files = []

  for i in get_pkgs_from_dir(repo_path):
    if i not in db_pkgs:
      print(" --> " + i)
      package_files.append(i)
      os.remove(repo_path + "/" + i)

  return package_files

# Make sure all of the packages exist
print("Removing old packages from local repo...")
remove_extra_pkgs(repo_local, repo)
print("Making sure all packages exist in the local repo...")
copy_pkgs = check_if_pkgs_exist(repo_local, repo)

# Copy packages
print("Copying packages...")
for i in copy_pkgs:
  print(" --> " + i)
  shutil.copy(repo_local + "/" + i, repo_remote + "/" + i)

# Copy database
print("Copying database...")
db_compressed = os.readlink(repo_local + "/" + repo + ".db")
print(" --> " + repo + ".db.tar.xz")
shutil.copyfile(repo_local + "/" + db_compressed,
                repo_remote + "/" + db_compressed)
print(" --> " + repo + ".db")
if os.path.exists(repo_remote + "/" + repo + ".db"):
  os.remove(repo_remote + "/" + repo + ".db")
os.symlink(db_compressed, repo_remote + "/" + repo + ".db")

# Copy files database
print("Copying files database...")
files_compressed = os.readlink(repo_local + "/" + repo + ".files")
print(" --> " + repo + ".files.tar.xz")
shutil.copyfile(repo_local + "/" + files_compressed,
                repo_remote + "/" + files_compressed)
print(" --> " + repo + ".files")
if os.path.exists(repo_remote + "/" + repo + ".files"):
  os.remove(repo_remote + "/" + repo + ".files")
os.symlink(files_compressed, repo_remote + "/" + repo + ".files")

# Make sure all of the packages in the remote repo exist
print("Removing old packages from remote repo...")
remove_extra_pkgs(repo_remote, repo)
print("Making sure all packages exist in the remote repo...")
copy_pkgs = check_if_pkgs_exist(repo_remote, repo)
