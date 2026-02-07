#!/bin/bash
dir=src
out="$dir/presenter99.bas"
rm -f $out
touch $out

# Recursively find all files, extract numbers, sort, and concatenate
find "$dir" -type f -not -name "presenter99.bas" | while read -r file; do

    # Skip if not a regular file
    [ -f "$file" ] || continue

    # Extract first non-space characters (the number)
    number=$(head -n 1 "$file" | sed 's/^[[:space:]]*//' | grep -o '^[0-9]*')

    # Skip files without a number
    [ -z "$number" ] && continue

    # Output: number, tab, filename (for sorting)
    echo -e "$number\t$file"
done | sort -n | while IFS=$'\t' read -r num file; do
    # Concatenate files in sorted order, removing empty lines
    grep -v '^[[:space:]]*$' "$file" >> $out
done
echo "Wrote to $out"
