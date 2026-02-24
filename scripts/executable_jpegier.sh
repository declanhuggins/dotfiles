#!/bin/bash
# Usage: ./jpgier.sh /path/to/source /path/to/destination

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <source_folder> <destination_folder>"
    exit 1
fi

SRC="$1"
DST="$2"

mkdir -p "$DST"

for file in "$SRC"/*; do
    if [[ "$file" =~ \.([jJ][pP][eE]?[gG]|[pP][nN][gG]|[cC][rR]2)$ ]]; then
        base=$(basename "$file")
        name="${base%.*}"
        out="$DST/${name}.jpg"

        # For CR2 files, prefix with "cr2:" as required by ImageMagick
        if [[ "$file" =~ \.[cC][rR]2$ ]]; then
            input="cr2:$file"
        else
            input="$file"
        fi

        # Extract image dimensions using ImageMagick identify
        dimensions=$(magick identify -format "%w %h" "$file")
        width=$(echo "$dimensions" | cut -d ' ' -f1)
        height=$(echo "$dimensions" | cut -d ' ' -f2)
        
        # Get the original file size in bytes
        filesize=$(stat -c%s "$file")
        
        # Convert the image to JPG, embedding width, height, and file size as metadata
        magick "$input" \
            -set "exif:ImageWidth" "$width" \
            -set "exif:ImageHeight" "$height" \
            -set "xmp:ImageWidth" "$width" \
            -set "xmp:ImageHeight" "$height" \
            -set "exif:FileSize" "$filesize" \
            "$out"

        if [ $? -eq 0 ]; then
            echo "Converted '$file' -> '$out'"
        else
            echo "Failed to convert '$file'"
        fi
    else
        echo "Skipping unsupported file: '$file'"
    fi
done
