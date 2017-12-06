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

backup="
  conf
  data/attic
  data/media
  data/media_attic
  data/media_meta
  data/meta
  data/pages
"

cd $dir
tar -cJvf $out $backup 
