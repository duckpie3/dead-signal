#!/bin/sh
# Prints every theme file of a folder as one line: <file name without .json> TAB <the JSON on one line>.
for f in "$1"/*.json; do
    [ -f "$f" ] || continue
    printf '%s\t' "$(basename "$f" .json)"
    tr -d '\n\r' < "$f"
    printf '\n'
done
