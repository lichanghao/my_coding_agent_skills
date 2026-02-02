#!/usr/bin/env bash
set -euo pipefail

VIDEO_IN="${1:?Usage: $0 video.mp4 image.jpg [output.mp4]}"
IMAGE_IN="${2:?Usage: $0 video.mp4 image.jpg [output.mp4]}"
OUT="${3:-output_cover.mp4}"

echo "Combining audio from clip with cover image..."
echo "Audio Source: $VIDEO_IN"
echo "Image Source: $IMAGE_IN"

# Use the image as the video stream (-map 1:v) and the input clip as the audio stream (-map 0:a).
# -loop 1: Loop the image indefinitely.
# -shortest: Stop encoding when the shortest stream (the audio) ends.
# -tune stillimage: Optimize encoding for static images.
# -vf "scale=...": Ensure width and height are divisible by 2 for libx264 compatibility.
# -c:a copy: Copy the audio stream directly without re-encoding to preserve quality.

ffmpeg -hide_banner -y \
  -i "$VIDEO_IN" \
  -loop 1 -i "$IMAGE_IN" \
  -map 1:v -map 0:a \
  -c:v libx264 -preset medium -crf 18 -tune stillimage \
  -vf "scale=trunc(iw/2)*2:trunc(ih/2)*2" \
  -c:a copy \
  -pix_fmt yuv420p \
  -shortest \
  "$OUT"

echo "Done. Output saved to $OUT"