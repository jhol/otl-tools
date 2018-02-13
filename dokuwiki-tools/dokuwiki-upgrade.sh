#!/bin/bash
#
# Upgrades a dokuwiki installation.
#

set -e
set -o pipefail
set -u

script_dir=$(dirname $0)

##
## Prints the usage message.
##
usage() {
  >&2 echo "Usage:"
  >&2 echo "  $0: DIR URL"
  exit 1
}

##
## Handle the script exiting
##
on_exit() {
  sudo sh -c "
      rm -f $dokuwiki_archive
      sudo rm -fr $dokuwiki_unpack_dir
    "
}

. $script_dir/check-util

#
# Check the system is ready to run the script
#

[ $# -eq 2 ] || usage
check_not_root
check_tools echo chown head ls mktemp mv rm tar true wget

dir=$1
url=$2

dokuwiki_archive=$(mktemp /tmp/dokuwiki_archive_XXXXXX)
dokuwiki_unpack_dir=$(mktemp -d /tmp/dokuwiki_unpack_XXXXXX)
trap "on_exit" EXIT

#
# Get root login
#

sudo true

#
# Downloading archive
#

echo Downloading...
wget -q -O $dokuwiki_archive "$url"

#
# Unpack the archive
#

echo Unpacking...
tar -C $dokuwiki_unpack_dir -xf $dokuwiki_archive
new_dokuwiki_dir=${dokuwiki_unpack_dir}/$(ls $dokuwiki_unpack_dir | head -n 1)

#
# Back up
#

echo Backing up...
backup_file=$($script_dir/dokuwiki-backup.sh $dir)

#
# Unpack the backup
#

echo Restoring backup...
sudo tar -xf $backup_file -C $new_dokuwiki_dir
sudo chown -R www-data:www-data $dokuwiki_unpack_dir

#
# Stop the server
#

echo Stopping server...
sudo systemctl stop nginx
sudo systemctl stop php5-fpm

#
# Replace installation
#

echo Replacing installation...
sudo sh -c "
    rm -rf $dir
    mv $new_dokuwiki_dir $dir
  "

#
# Stop the server
#

echo Restarting server...
sudo systemctl start nginx
sudo systemctl start php5-fpm

echo Done
