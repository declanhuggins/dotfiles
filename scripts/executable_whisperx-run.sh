#!/usr/bin/env zsh

source "$(conda info --base)/etc/profile.d/conda.sh"

# Activate the whisperx conda environment
conda activate whisperx

# Create output directory if it doesn't exist
mkdir -p ~/Whisper

# Get filename and directory from the first argument
filename=$(basename "$1")
filedir=$(dirname "$1")

# Run whisperx with the provided argument and options
whisperx "$1" --compute_type int8 --hf_token "$HUGGING_FACE_TOKEN" --diarize --output_dir ~/Whisper

# Deactivate the conda environment
conda deactivate

# Define paths for subtitle file and output video file
srt_file="${HOME}/Whisper/${filename%.webm}.srt"
output_file="${filedir}/${filename%.webm}_with_subtitles.webm"

# Check if the input file has a video stream
has_video=$(ffmpeg -i "$1" 2>&1 | grep -i "Video:")

if [ -z "$has_video" ]; then
    echo "No video stream detected. Adding a 1920x1080 black video placeholder with subtitles..."
    ffmpeg -f lavfi -i color=size=1920x1080:rate=1:color=black \
          -i "$1" \
          -vf "subtitles=${srt_file},format=yuv420p" \
          -shortest -map 1:a -map 0:v \
          -c:v libvpx -c:a copy \
          "${output_file}"
else
    echo "Video stream detected. Embedding subtitles..."
    ffmpeg -i "$1" \
          -vf "subtitles=${srt_file},format=yuv420p" \
          -c:a copy -c:v libvpx \
          "${output_file}"
fi

echo "Subtitled file created at: ${output_file}"