#!/bin/bash
#
# Creates a backup tar-ball of a DokuWiki deployment.
#

set -e

usage() {
  >&2 echo "Usage:"
  >&2 echo "  $0: DIR"
  exit 1
}

[ $# -eq 1 ] || usage

dir=$1
out=$(pwd)/$(date +%Y%m%d)-$(basename $dir | sed 's/[^A-Za-z0-9]/-/g').tar.xz

cd $dir

backup="
  conf
  data/attic
  data/media
  data/media_attic
  data/media_meta
  data/meta
  data/pages
  lib/tpl/dokuwiki/images/favicon.ico
  $(ls lib/plugins | grep -v \
    -e 'acl' \
    -e 'action.php' \
    -e 'admin.php' \
    -e 'auth.php' \
    -e 'authad' \
    -e 'authldap' \
    -e 'authmysql' \
    -e 'authpdo' \
    -e 'authpgsql' \
    -e 'authplain' \
    -e 'config' \
    -e 'extension' \
    -e 'index.html' \
    -e 'info' \
    -e 'popularity' \
    -e 'remote.php' \
    -e 'revert' \
    -e 'safefnrecode' \
    -e 'styling' \
    -e 'syntax.php' \
    -e 'usermanager' |
    sed 's_.*_lib/plugins/&_')
  $(ls lib/tpl | grep -v \
    -e 'dokuwiki' \
    -e 'index.php' |
    sed 's_.*_lib/tpl/&_')
"

tar -cJvf $out $backup 
