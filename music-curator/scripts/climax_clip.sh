#!/usr/bin/env bash
set -euo pipefail

IN="${1:?Usage: $0 input.mp4 [output.mp4]}"
OUT="${2:-clip.mp4}"

CLIP_LEN="${CLIP_LEN:-35}"   # seconds to cut
WIN="${WIN:-4}"              # loudness analysis window length (sec)
STEP="${STEP:-2}"            # step between windows (sec); try 2 for faster
PRE_ROLL="${PRE_ROLL:-5}"   # seconds before climax to start clip
MODE="${MODE:-reencode}"     # reencode | copy

# Get duration (integer seconds)
DUR="$(ffprobe -v error -show_entries format=duration -of default=nk=1:nw=1 "$IN")"
DUR_S="$(python3 - <<PY
import math
print(int(math.floor(float("$DUR"))))
PY
)"

# Search windows in [0, DUR-WIN]
MAX_START=$(( DUR_S - WIN ))
if (( MAX_START < 0 )); then MAX_START=0; fi

best_t=0
best_I=-1e9  # LUFS, larger (less negative) = louder

tmp="$(mktemp -t eburseg.XXXXXX.log)"
trap 'rm -f "$tmp"' EXIT

echo "Scanning loudness windows: WIN=${WIN}s STEP=${STEP}s (this may take a bit)..."

t=0
while (( t <= MAX_START )); do
  # Run ebur128 on a short segment and parse the Summary "I:" line
  # We keep logs in $tmp
  ffmpeg -hide_banner -nostats -ss "$t" -t "$WIN" -i "$IN" \
    -vn -af ebur128 -f null - 2> "$tmp" || true

  I="$(awk '/Integrated loudness:/{flag=1;next} flag && $1=="I:"{print $2; exit}' "$tmp")"

  # If parsing failed, skip this window
  if [[ -n "${I:-}" ]]; then
    # Compare as float: pick max I (less negative)
    better="$(python3 - <<PY
best=float("$best_I")
cur=float("$I")
print(1 if cur>best else 0)
PY
)"
    if [[ "$better" == "1" ]]; then
      best_I="$I"
      best_t="$t"
    fi
  fi

  t=$(( t + STEP ))
done

# Clamp clip start so we don't run past end
# Shift start earlier by PRE_ROLL seconds
start=$(( best_t - PRE_ROLL ))
if (( start < 0 )); then start=0; fi

# Clamp to video duration
if (( start + CLIP_LEN > DUR_S )); then
  start=$(( DUR_S - CLIP_LEN ))
  if (( start < 0 )); then start=0; fi
fi

echo "Best window start (climax detected): ${best_t}s"
echo "Pre-roll applied: ${PRE_ROLL}s"
echo "Final clip start: ${start}s"

if [[ "$MODE" == "copy" ]]; then
  # Fast, lossless, may snap to keyframes
  ffmpeg -hide_banner -y -ss "$start" -t "$CLIP_LEN" -i "$IN" -c copy "$OUT"
else
  # Accurate timing
  ffmpeg -hide_banner -y -ss "$start" -t "$CLIP_LEN" -i "$IN" \
    -c:v libx264 -crf 18 -preset medium \
    -c:a aac -b:a 192k -movflags +faststart \
    "$OUT"
fi