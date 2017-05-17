#!/usr/bin/python3

import sys
from subprocess import call

def usage():
    print('{0} FACTOR IN OUT'.format(sys.argv[0]))
    sys.exit(1)

if len(sys.argv) != 4:
    usage()

factor = int(sys.argv[1])
in_file = sys.argv[2]
out_file = sys.argv[3]

logf = [p for p in range(1, 32) if 2**p == factor]
if len(logf) == 1:
    logf = logf[0]
else:
    usage()

cmd = ['ffmpeg', '-i', in_file, '-y',
        '-filter_complex',
        '[0:v]' + 'tblend=average,framestep=2,' * logf +
            'setpts={0}*PTS'.format(1.0 / factor) + '[v];'
            '[0:a]' + ','.join(['atempo=2.0'] * logf) + '[a]',
        '-map', '[v]', '-map', '[a]', '-r', '30', out_file]
print(' '.join(cmd))
call(cmd)
