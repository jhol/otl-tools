#!/usr/bin/env python3

import argparse
import os
import sys
from subprocess import call

parser = argparse.ArgumentParser(
    description='Generates a timelapse video.')
parser.add_argument('factor', metavar='FACTOR', type=int, nargs=1,
    help='The speed-up factor (must be a power-of-2)')
parser.add_argument('in_files', metavar='IN', type=str, nargs='+',
    help='The input file')
parser.add_argument('out_file', metavar='OUT', type=str, nargs=1,
    help='The output files', default='out.mp4')
parser.add_argument('-a', '--with-audio', action='store_true',
    help='Include audio')
args = parser.parse_args()

factor = args.factor[0]
in_files = args.in_files
out_file = args.out_file[0]

logf = [p for p in range(1, 32) if 2**p == factor]
if len(logf) == 1:
    logf = logf[0]
else:
    print('FACTOR must be a power-of-2\n')

filter_complex = (
    ''.join(['[{0}:v] '.format(i) for i in range(len(in_files))]) +
    'concat=n={0}:v=1:a=0,'.format(len(in_files)) +
    'tblend=average,framestep=2,' * logf +
    'setpts={0}*PTS'.format(1.0 / factor) + '[v]')
if args.with_audio:
    filter_complex += (';' +
        ''.join(['[{0}:a] '.format(i) for i in range(len(in_files))]) +
        'concat=n={0}:v=0:a=1,'.format(len(in_files)) +
        ','.join(['atempo=2.0'] * logf) + '[a]')

mappings = ['-map', '[v]']
if args.with_audio:
    mappings += ['-map', '[a]']

cmd = (['ffmpeg', '-y'] +
        sum([['-i', f] for f in in_files], []) +
        ['-filter_complex', filter_complex] +
        mappings + ['-r', '30', out_file])
print(' '.join(cmd))
call(cmd)
