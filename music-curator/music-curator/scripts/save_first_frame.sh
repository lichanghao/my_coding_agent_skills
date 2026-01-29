#!/bin/bash

# Check if an argument is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <video_file>"
  exit 1
fi

VIDEO_FILE="$1"
# Replace extension with .jpg for the output file
OUTPUT_FILE="${VIDEO_FILE%.*}.jpg"

# Extract the first frame using ffmpeg starting at 10s
# -ss 10: seek to 10 seconds
# -i: input file
# -vframes 1: output strictly one video frame
# -q:v 2: set quality for jpg (2 is high quality, range is 1-31)
ffmpeg -y -ss 10 -i "$VIDEO_FILE" -vframes 1 -q:v 2 "$OUTPUT_FILE"

if [ $? -eq 0 ]; then
  echo "Frame at 10s saved to $OUTPUT_FILE"
else
  echo "Error extracting frame."
  exit 1
fi
