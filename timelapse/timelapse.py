#!/usr/bin/python3

import argparse
import os
import sys
from subprocess import call

concat_file = '/tmp/concat.txt'

parser = argparse.ArgumentParser(
    description='Generates a timelapse video.')
parser.add_argument('factor', metavar='FACTOR', type=int, nargs=1,
    help='The speed-up factor (must be a power-of-2)')
parser.add_argument('in_files', metavar='IN', type=str, nargs='+',
    help='The output file')
parser.add_argument('out_file', metavar='OUT', type=str, nargs=1,
    help='The input files', default='out.mp4')
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

with open(concat_file, 'w') as f:
    for i in in_files:
        f.write("file '" + os.path.abspath(i) + "'\n")

filter_complex = ('[0:v]' + 'tblend=average,framestep=2,' * logf +
    'setpts={0}*PTS'.format(1.0 / factor) + '[v]')
if args.with_audio:
    filter_complex += ';[0:a]' + ','.join(['atempo=2.0'] * logf) + '[a]'

mappings = ['-map', '[v]']
if args.with_audio:
    mappings += ['-map', '[a]']

cmd = (['ffmpeg', '-f', 'concat', '-safe', '0', '-i', concat_file, '-y',
        '-filter_complex', filter_complex] +
        mappings + ['-r', '30', out_file])
print(' '.join(cmd))
call(cmd)

os.remove(concat_file)
