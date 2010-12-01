#!/bin/sh
set -ue
CORPUS=$1
LANG=$2
cat $CORPUS.$LANG | tail -n+1     | head -n 2000  > $CORPUS.dev.$LANG
cat $CORPUS.$LANG | tail -n+2001  | head -n 10000 > $CORPUS.test.$LANG
cat $CORPUS.$LANG | tail -n+12001                 > $CORPUS.train.$LANG
