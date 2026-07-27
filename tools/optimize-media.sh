#!/usr/bin/env bash
# Prepare a media file for committing to assets/. See MEDIA.md.
#
#   tools/optimize-media.sh <source-file> <dest-dir> [output-basename]
#
# Images  -> max 1600px, JPEG q82 progressive (PNG kept if it has transparency)
# Video   -> max 1280px, H.264 CRF 26, +faststart
# GIF     -> converted to muted mp4 (never committed as GIF)
set -euo pipefail

SRC=${1:?usage: optimize-media.sh <source-file> <dest-dir> [output-basename]}
DEST=${2:?usage: optimize-media.sh <source-file> <dest-dir> [output-basename]}
[ -f "$SRC" ] || { echo "no such file: $SRC" >&2; exit 1; }
mkdir -p "$DEST"

# lowercase-kebab the name unless one was supplied
if [ $# -ge 3 ]; then
  STEM=$3
else
  STEM=$(basename "${SRC%.*}" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]\+/-/g; s/^-//; s/-$//')
fi

find_ffmpeg() {
  command -v ffmpeg 2>/dev/null && return
  python3 -c 'import imageio_ffmpeg;print(imageio_ffmpeg.get_ffmpeg_exe())' 2>/dev/null && return
  echo "ffmpeg not found. Install it, or: pip install imageio-ffmpeg" >&2
  exit 1
}

ext=$(printf '%s' "${SRC##*.}" | tr '[:upper:]' '[:lower:]')

case "$ext" in
  jpg|jpeg|png|webp|heic|tif|tiff)
    OUT="$DEST/$STEM"
    python3 - "$SRC" "$OUT" <<'PY'
from PIL import Image, ImageOps
import sys, os
src, out = sys.argv[1], sys.argv[2]
im = Image.open(src)
fmt = im.format
im = ImageOps.exif_transpose(im)          # bake rotation in before metadata is dropped
w, h = im.size
MAX = 1600
if max(w, h) > MAX:
    r = MAX / max(w, h)
    im = im.resize((round(w * r), round(h * r)), Image.LANCZOS)
if fmt == 'PNG' and im.mode in ('RGBA', 'LA', 'P'):
    out += '.png'; im.save(out, 'PNG', optimize=True)
else:
    out += '.jpg'; im.convert('RGB').save(out, 'JPEG', quality=82, optimize=True, progressive=True)
print(f"{out}  {im.size[0]}x{im.size[1]}  {os.path.getsize(out)/1024:.0f} KB")
if os.path.getsize(out) > 500_000:
    print("  WARNING: over the 500 KB budget in MEDIA.md")
PY
    ;;

  gif)
    FF=$(find_ffmpeg)
    OUT="$DEST/$STEM.mp4"
    # never upscale a small GIF; cap long side at 1280
    "$FF" -y -loglevel error -i "$SRC" \
      -c:v libx264 -crf 27 -preset veryslow -pix_fmt yuv420p \
      -vf "scale='min(1280,iw)':-2,fps=20" -an -movflags +faststart "$OUT"
    echo "$OUT  $(du -h "$OUT" | cut -f1)"
    echo "  Embed with: <video src=\"/${OUT#./}\" autoplay loop muted playsinline width=\"100%\"></video>"
    ;;

  mp4|mov|webm|m4v|avi|mkv)
    FF=$(find_ffmpeg)
    OUT="$DEST/$STEM.mp4"
    if "$FF" -i "$SRC" 2>&1 | grep -q 'Stream.*Audio'; then AUD="-c:a aac -b:a 96k"; else AUD="-an"; fi
    # shellcheck disable=SC2086
    "$FF" -y -loglevel error -i "$SRC" \
      -c:v libx264 -crf 26 -preset slow -pix_fmt yuv420p \
      -vf "scale=w=1280:h=1280:force_original_aspect_ratio=decrease:force_divisible_by=2" \
      $AUD -movflags +faststart "$OUT"
    sz=$(stat -c%s "$OUT")
    echo "$OUT  $(du -h "$OUT" | cut -f1)"
    [ "$sz" -gt 12582912 ] && echo "  WARNING: over the 12 MB budget in MEDIA.md — consider trimming the clip"
    ;;

  svg|pdf)
    cp "$SRC" "$DEST/$STEM.$ext"
    echo "$DEST/$STEM.$ext  (copied as-is)"
    ;;

  *)
    echo "unhandled type: .$ext" >&2; exit 1 ;;
esac
