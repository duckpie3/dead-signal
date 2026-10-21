#!/bin/sh
# Lists the images in $1 (one level of sub-folders included), sorted by name.
# Output, tab separated:  path <TAB> bytes <TAB> "width height" (empty when unknown)
dir=$1
case "$dir" in
    "~"*) dir="$HOME${dir#\~}" ;;
esac
[ -d "$dir" ] || exit 0

have_identify=0
command -v identify >/dev/null 2>&1 && have_identify=1

find -L "$dir" -maxdepth 2 -type f \
    \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \
       -o -iname '*.bmp' -o -iname '*.gif' -o -iname '*.avif' -o -iname '*.jxl' \) 2>/dev/null \
    | sort -f \
    | while IFS= read -r f; do
        size=$(stat -c %s "$f" 2>/dev/null || echo 0)
        dim=""
        if [ "$have_identify" = 1 ]; then
            dim=$(identify -format '%w %h' "$f[0]" 2>/dev/null)
        fi
        if [ -z "$dim" ]; then
            # Fallback: `file` prints ", 3840 x 2160," for PNG and ", 3840x2160," for JPEG.
            dim=$(file -b "$f" 2>/dev/null \
                | sed -n 's/.*, \([0-9]\{3,5\}\) \{0,1\}x \{0,1\}\([0-9]\{3,5\}\)\(,\| \|$\).*/\1 \2/p' | head -n 1)
        fi
        printf '%s\t%s\t%s\n' "$f" "$size" "$dim"
    done
