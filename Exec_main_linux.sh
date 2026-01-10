#!/bin/bash

mkfifo outstream
echo "$1">outstream
sleep 1
echo "test1">outstream
sleep 1
echo "test2">outstream
sleep 1
echo "test3">outstream
echo "gata"