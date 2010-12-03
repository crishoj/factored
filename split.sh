#!/bin/sh
set -ue
CORPUS=$1
mkdir -p dev
mkdir -p test
mkdir -p train
cat $CORPUS | tail -n+1     | head -n 2000  > dev/$CORPUS
cat $CORPUS | tail -n+2001  | head -n 10000 > test/$CORPUS
cat $CORPUS | tail -n+12001                 > train/$CORPUS
