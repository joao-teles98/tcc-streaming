#!/bin/bash

INPUT_VIDEO="$1"

BASE_FILENAME="${INPUT_VIDEO%.*}"
OUTPUT_DIR="$BASE_FILENAME"

RESOLUTIONS=("3840x2160" "1920x1080" "1280x720" "640x360")
VIDEO_BITRATES=("copy" "50000k" "20000k" "10000k" "5000k" "2500k" "1000k")
AUDIO_BITRATE="128k"

mkdir -p "$OUTPUT_DIR"

for resolution in "${RESOLUTIONS[@]}"; do
    for bitrate in "${VIDEO_BITRATES[@]}"; do
        output_file="$OUTPUT_DIR/${BASE_FILENAME}-${resolution}-${bitrate}.mp4"
        ffmpeg -i "$INPUT_VIDEO" \
            -vf scale="$resolution" \
            -c:v libx264 -b:v "$bitrate" \
            -c:a aac -b:a "$AUDIO_BITRATE" \
            "$output_file"
        echo "Encoded: $output_file"
    done
done

echo "Encoding complete."
