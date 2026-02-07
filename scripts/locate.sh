#!/bin/bash
# Usage: ./locate.sh <line_number>

# If no args provided, ask for them
if [ $# -eq 0 ]; then
    read -p "Enter line number to locate: " line_num
elif [ $# -ne 1 ]; then
    echo "Usage: $0 <line_number>"
    echo "Example: $0 1050"
    exit 1
else
    line_num="$1"
fi

# Search for the line number in all .bas files
found=false
for file in $(find src -name "*.bas"); do
    [ -f "$file" ] || continue
    
    # Check if this file contains the line number
    if grep -q "^[[:space:]]*$line_num[[:space:]]" "$file"; then
        echo "$file"
        found=true
        break
    fi
done

if [ "$found" = false ]; then
    echo "Line number $line_num not found in any .bas file"
    exit 1
fi
