#!/bin/bash
# Check if a directory argument was provided
if [ -z "$1" ]; then
    echo "Usage: $0 /path/to/parent/folder"
    exit 1
fi

BASE_DIR="$1"

# Recursively find all .epub files in all subdirectories and convert them to .pdf using Calibre's ebook-convert
find "$BASE_DIR" -type f -name "*.epub" -print0 | while IFS= read -r -d '' epub; do
    # Create output file name by replacing .epub with .pdf
    pdf="${epub%.epub}.pdf"
    echo "Converting '$epub' to '$pdf'"
    ebook-convert "$epub" "$pdf"
done
