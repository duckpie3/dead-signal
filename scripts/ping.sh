#!/bin/sh
# Prints the round-trip time in ms for one ping to $1, or nothing on failure.
ping -n -c 1 -W 1 "$1" 2>/dev/null | sed -n 's/.*time=\([0-9.]*\).*/\1/p'
