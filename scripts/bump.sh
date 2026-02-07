#!/bin/bash
# Usage: ./bump.sh <amount> [min_line]
# If no args provided, ask for them
if [ $# -eq 0 ]; then
    read -p "Enter amount to bump: " amount
    read -p "Enter minimum line number (or press Enter for all): " min_line
    min_line=${min_line:-0}
elif [ $# -eq 1 ]; then
    amount="$1"
    min_line=0
elif [ $# -eq 2 ]; then
    amount="$1"
    min_line="$2"
else
    echo "Usage: $0 <amount> [min_line]"
    echo "Example: $0 100           # Bump all lines by 100"
    echo "Example: $0 100 1000      # Bump only lines >= 1000 by 100"
    exit 1
fi

dir="src"

echo "==================================="
echo "  Bumping line numbers"
echo "  Amount: +$amount"
echo "  Minimum: $min_line"
echo "==================================="
echo

# Build mapping of old -> new line numbers
declare -A line_map

# First pass: build the mapping from ALL files
find "$dir" -type f -not -name "presenter99.bas" | while read -r file; do
    [ -f "$file" ] || continue
    [ "$(basename "$file")" = "presenter99.bas" ] && continue
    
    while IFS= read -r line; do
        if [[ "$line" =~ ^[[:space:]]*[0-9]+ ]]; then
            old_num=$(echo "$line" | grep -o '^[[:space:]]*[0-9][0-9]*' | tr -d ' ')
            if [ "$old_num" -ge "$min_line" ]; then
                new_num=$((old_num + amount))
                line_map[$old_num]=$new_num
            fi
        fi
    done < "$file"
done

# Second pass: update ALL files
find "$dir" -type f -not -name "presenter99.bas" | while read -r file; do
    [ -f "$file" ] || continue
    [ "$(basename "$file")" = "presenter99.bas" ] && continue
    
    temp=$(mktemp)
    modified=false
    
    while IFS= read -r line; do
        new_line="$line"
        
        # Update line number itself if it qualifies
        if [[ "$line" =~ ^[[:space:]]*[0-9]+ ]]; then
            old_num=$(echo "$line" | grep -o '^[[:space:]]*[0-9][0-9]*' | tr -d ' ')
            if [ "$old_num" -ge "$min_line" ]; then
                new_num=$((old_num + amount))
                code=$(echo "$line" | sed 's/^[[:space:]]*[0-9][0-9]*//')
                new_line="$new_num$code"
                modified=true
            fi
        fi
        
        # Update references (GOTO, GOSUB, THEN, ELSE)
        for old_num in "${!line_map[@]}"; do
            new_num="${line_map[$old_num]}"
            new_line=$(echo "$new_line" | sed -E "s/(GOTO[[:space:]]+)$old_num([^0-9]|$)/\1$new_num\2/g")
            new_line=$(echo "$new_line" | sed -E "s/(THEN[[:space:]]+)$old_num([^0-9]|$)/\1$new_num\2/g")
            new_line=$(echo "$new_line" | sed -E "s/(ELSE[[:space:]]+)$old_num([^0-9]|$)/\1$new_num\2/g")
            new_line=$(echo "$new_line" | sed -E "s/(GOSUB[[:space:]]+)$old_num([^0-9]|$)/\1$new_num\2/g")
            
            if [ "$new_line" != "$line" ]; then
                modified=true
            fi
        done
        
        echo "$new_line" >> "$temp"
    done < "$file"
    
    if [ "$modified" = true ]; then
        mv "$temp" "$file"
        echo " Updated $(basename "$file")"
    else
        rm "$temp"
    fi
done

echo
echo "==================================="
echo " Bump complete!"
echo "==================================="
