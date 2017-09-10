#!/bin/bash

set -e

usage() {
  >&2 echo "Usage: $0 IN_FILE OUT_FILE [START [DURATION]]"
  exit 1
}

[ $# -lt 2 -o $# -gt 4 ] && usage

readonly in_file=$1
readonly out_file=$2

[ $# -gt 2 ] && period="-ss $3" && [ $# -gt 3 ] && period="$period -t $4"

readonly cropped=$(mktemp XXXXXX.mkv)
readonly wav=$(mktemp XXXXXX.wav)
readonly wav_out=$(mktemp XXXXXX.wav)

on_exit() {
  [ -f $cropped ] && rm $cropped
  [ -f $wav ] && rm $wav
  [ -f $wav_out ] && rm $wav_out
}

trap "on_exit" EXIT

rm $cropped $wav $wav_out

if [ -n "$period" ]; then
  echo "Extracting clip..."
  ffmpeg -loglevel 16 $period -i $in_file -codec copy $cropped
  in_file="$cropped"
fi

echo "Processing audio..."
ffmpeg -loglevel 16 -i $in_file -acodec pcm_s16le $wav
sox $wav $wav_out \
  remix - \
  gain -n -6 \
  bass -8.1 250 \
  compand 0.02,4 5:-60,-40,-10 -9 -90 2

if expr "$out_file" : '.*\.flac$' >/dev/null || \
  expr "$out_file" : '.*\.wav$' >/dev/null ; then
  echo "Encoding audio..."
  ffmpeg -loglevel 16 -i $wav_out $out_file
else
  echo "Re-attaching audio..."
  ffmpeg -loglevel 16 -i $in_file -i $wav_out -c:v copy -map 0:v:0 -map 1:a:0 $out_file
fi
