#!/bin/bash

# Directory to search (default: src)
dir=src

# Associate array to track line_number -> file
declare -A line_files

# Track if we found any collisions
collision_found=false

# Scan all .bas files
find "$dir" -type f -not -name "slideshow99.bas" | while read -r file; do
    [ -f "$file" ] || continue
    
    # Extract line numbers from this file
    while IFS= read -r line; do
        if [[ "$line" =~ ^[[:space:]]*([0-9]+)[[:space:]] ]]; then
            line_num="${BASH_REMATCH[1]}"
            
            # Check if we've seen this line number before
            if [ -n "${line_files[$line_num]}" ]; then
                echo "COLLISION: Line $line_num"
                echo "  File 1: ${line_files[$line_num]}"
                echo "  File 2: $file"
                echo
                collision_found=true
            else
                # Record this line number
                line_files[$line_num]="$file"
            fi
        fi
    done < "$file"
done

if [ "$collision_found" = true ]; then
    echo "Collisions detected - please rebase your files"
    exit 1
fi
