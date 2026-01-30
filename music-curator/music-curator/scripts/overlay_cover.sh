#!/usr/bin/env bash
set -euo pipefail

VIDEO_IN="${1:?Usage: $0 video.mp4 image.jpg [output.mp4]}"
IMAGE_IN="${2:?Usage: $0 video.mp4 image.jpg [output.mp4]}"
OUT="${3:-output_overlay.mp4}"

POSITION="${POSITION:-center}" # center | top | bottom

# Get dimensions of the cover image
eval "$(ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of default=noprint_wrappers=1:nokey=0 \"$IMAGE_IN\" | sed 's/^/IMG_/'))"
# Returns IMG_width=... and IMG_height=...

echo "Cover Image Dimensions: ${IMG_width}x${IMG_height}"

# Calculate overlay coordinates based on POSITION
# We scale the video to fit inside the image width (with some margin? maybe just fit width)
# Assuming we want to fit the video within the image canvas, preserving aspect ratio.

# Complex Filter Explanation:
# 1. [1:v] (Image) is the background.
# 2. [0:v] (Video) is scaled to fit within IMG_width x IMG_height.
#    force_original_aspect_ratio=decrease ensures it fits inside.
# 3. Overlay logic based on POSITION.

case "$POSITION" in
  top)
    # Center horizontally, stick to top (with slight padding maybe?)
    Y_POS="0"
    ;;
  bottom)
    # Center horizontally, stick to bottom
    Y_POS="H-h"
    ;;
  *)
    # Default to center
    Y_POS="(H-h)/2"
    ;;
esac

X_POS="(W-w)/2"

echo "Composing video..."
echo "Video: $VIDEO_IN"
echo "Image: $IMAGE_IN"
echo "Position: $POSITION"

ffmpeg -hide_banner -y \
  -i "$VIDEO_IN" \
  -loop 1 -i "$IMAGE_IN" \
  -filter_complex "
    [0:v]scale=$IMG_width:$IMG_height:force_original_aspect_ratio=decrease[vid];
    [1:v][vid]overlay=x=$X_POS:y=$Y_POS:shortest=1:format=auto
  " \
  -c:v libx264 -crf 18 -preset medium \
  -c:a copy \
  -pix_fmt yuv420p \
  "$OUT"

echo "Done. Output saved to $OUT"
