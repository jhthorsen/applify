#!/bin/sh

if [ "x$1" = "x" ]; then
    echo "Usage: $0 path/to/script.pl";
    exit;
fi

SCRIPT="$1"
NAME=$(basename $1 .pl)

pp -I lib -B -c -o $NAME.bin $SCRIPT

./$NAME.bin --help

rm -f $NAME.bin
