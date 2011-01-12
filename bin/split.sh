#!/bin/sh
set -ue
DEV_COUNT=$1
TEST_COUNT=$2
CORPUS=$3
mkdir -p dev
mkdir -p test
mkdir -p train
cat $CORPUS | tail -n+1 | head -n $DEV_COUNT > dev/$CORPUS
cat $CORPUS | tail -n+$((DEV_COUNT + 1)) | head -n $TEST_COUNT > test/$CORPUS
cat $CORPUS | tail -n+$((DEV_COUNT + TEST_COUNT + 1)) > train/$CORPUS
