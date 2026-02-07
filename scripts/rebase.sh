#!/bin/bash
# Usage: ./rebase.sh <file> <start_line> <increment>

# If no args provided, ask for them
if [ $# -eq 0 ]; then
    read -p "Enter file path: " file
    read -p "Enter start line number: " start
    read -p "Enter increment: " increment
elif [ $# -ne 3 ]; then
    echo "Usage: $0 <file> <start_line> <increment>"
    echo "Example: $0 myfile.bas 1000 10"
    exit 1
else
    file="$1"
    start="$2"
    increment="$3"
fi

if [ ! -f "$file" ]; then
    echo "Error: File '$file' not found"
    exit 1
fi

# Build mapping of old -> new line numbers
declare -A line_map
current=$start
while IFS= read -r line; do
    if [[ "$line" =~ ^[[:space:]]*[0-9]+ ]]; then
        old_num=$(echo "$line" | grep -o '^[[:space:]]*[0-9][0-9]*' | tr -d ' ')
        line_map[$old_num]=$current
        current=$((current + increment))
    fi
done < "$file"

# Create temporary file for the rebased file
temp=$(mktemp)

# Rebase the file itself
current=$start
while IFS= read -r line; do
    if [[ "$line" =~ ^[[:space:]]*[0-9]+ ]]; then
        code=$(echo "$line" | sed 's/^[[:space:]]*[0-9][0-9]*//')
        echo "$current$code" >> "$temp"
        current=$((current + increment))
    else
        echo "$line" >> "$temp"
    fi
done < "$file"

# Replace original file
mv "$temp" "$file"

echo "Rebased $file starting at $start with increment $increment"

# Update all references in other .bas files
dir=$(dirname "$file")
for other_file in "$dir"/*.bas; do
    [ "$other_file" = "$file" ] && continue  # Skip the file we just rebased
    [ -f "$other_file" ] || continue
    
    temp=$(mktemp)
    modified=false
    
    while IFS= read -r line; do
        new_line="$line"
        
        # Replace GOTO references
        for old_num in "${!line_map[@]}"; do
            new_num="${line_map[$old_num]}"
            # Match GOTO <num>, THEN <num>, ELSE <num>, GOSUB <num>
            new_line=$(echo "$new_line" | sed -E "s/(GOTO[[:space:]]+)$old_num([^0-9]|$)/\1$new_num\2/g")
            new_line=$(echo "$new_line" | sed -E "s/(THEN[[:space:]]+)$old_num([^0-9]|$)/\1$new_num\2/g")
            new_line=$(echo "$new_line" | sed -E "s/(ELSE[[:space:]]+)$old_num([^0-9]|$)/\1$new_num\2/g")
            new_line=$(echo "$new_line" | sed -E "s/(GOSUB[[:space:]]+)$old_num([^0-9]|$)/\1$new_num\2/g")
        done
        
        if [ "$new_line" != "$line" ]; then
            modified=true
        fi
        
        echo "$new_line" >> "$temp"
    done < "$other_file"
    
    if [ "$modified" = true ]; then
        mv "$temp" "$other_file"
        echo "Updated references in $other_file"
    else
        rm "$temp"
    fi
done

echo "Done!"
