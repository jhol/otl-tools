#!/bin/bash

trap "trap - SIGTERM && kill -- -$$" SIGINT SIGTERM EXIT

v4l2-ctl -d /dev/video1 -c exposure_absolute=100,focus_absolute=10

ffmpeg -y -i rtsp://192.168.1.150/ufirststream -vcodec copy 3d-printer.mkv &
ffmpeg -y -i rtsp://192.168.1.138/ufirststream -vcodec copy wide.mkv &
socat UDP-RECV:5004,reuseaddr UDP-DATAGRAM:localhost:12000 &

socat UDP-RECV:5004,reuseaddr | \
  ffmpeg -y -i - -vcodec copy microscope.mkv &
arecord -t wav -r 48000 -f S16_LE -c 2 audio.wav
