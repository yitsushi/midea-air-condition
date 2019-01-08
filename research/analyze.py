#!/usr/bin/env python

import struct
import sys

if len(sys.argv) < 2:
    print("not enough parameters")
    exit(0)

mylist = sys.argv[1].split(',')
size = 8
if len(sys.argv) > 2:
    size = int(sys.argv[2])

form = 'Q'
if len(sys.argv) > 3:
    form = sys.argv[3]

sform = 'd'
if len(sys.argv) > 4:
    sform = sys.argv[4]

for i in range(len(mylist)-(size - 1)):
    current_block = bytearray([(int(x) & 0xff) for x in mylist[i:i+size]])
    s_form = "%%2d -> %%%s" % (sform)
    print(s_form % (i, struct.unpack(form, current_block)[0]))

