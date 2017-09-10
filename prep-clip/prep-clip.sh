#!/bin/bash

set -e

readonly vocalrediso="/usr/share/audacity/plug-ins/vocalrediso.ny"

##
## Prints usage text
##
usage() {
  >&2 echo "Usage: $0 [-i] IN_FILE OUT_FILE [START [DURATION]]"
  >&2 echo
  >&2 echo "  -h  Prints this text."
  >&2 echo "  -i  Performs vocal isolation on the audio."
  >&2 echo
  exit 1
}

#
# Parse arguments
#

isolate=''

while getopts "ih" opt; do
  case $opt in
    i)
      isolate='yes'
      ;;

    h)
      usage
      ;;
  esac
done

shift $((OPTIND-1))
[ $# -lt 2 -o $# -gt 4 ] && usage

readonly in_file=$1
readonly out_file=$2

[ $# -gt 2 ] && period="-ss $3" && [ $# -gt 3 ] && period="$period -t $4"

#
# Set up temporary files
#

readonly cropped=$(mktemp -p '' XXXXXX.mkv)
readonly wav_extracted=$(mktemp -p '' XXXXXX.wav)
readonly wav_isolated=$(mktemp -p '' XXXXXX.wav)
readonly wav_out=$(mktemp -p '' XXXXXX.wav)
readonly process_ny=$(mktemp -p '' process-XXXXXX.ny)

on_exit() {
  for f in $cropped $wav $wav_isolated $wav_out $process_ny; do
    [ -f $f ] && rm $f
  done
}

trap "on_exit" EXIT

rm $cropped $wav_extracted $wav_isolated $wav_out

#
# Process video
#

if [ -n "$period" ]; then
  echo "Extracting clip..."
  ffmpeg -loglevel 16 $period -i $in_file -codec copy $cropped
  in_file="$cropped"
fi

echo "Processing audio..."
echo "    ffmpeg"
ffmpeg -loglevel 16 -i $in_file -acodec pcm_s16le $wav_extracted

if [ "xyes" = "x$isolate" ]; then
  echo "    ny"
  cat > $process_ny <<EOF
(setf plug-in "${vocalrediso}")
(setf in-file "${wav_extracted}")
(setf out-file "${wav_isolated}")

(setf action 1)
(setf strength 1.0)
(setf high-transition 9000.0)
(setf low-transition 40.0)
(setf strength 1.0)

(setf *track* (s-read in-file))
(setf len (snd-length (aref *track* 0) 160000000))

(do* ((fp (open plug-in :direction :input))
      (ex (read fp nil) (read fp nil)))
  ((null ex) (close fp) nil)
  (eval ex))

(s-save (catalog) len out-file)

(exit)
EOF
  ny -l $process_ny >/dev/null

  wav="$wav_isolated"
else
  wav="$wav_extracted"
fi

echo "    sox"
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
