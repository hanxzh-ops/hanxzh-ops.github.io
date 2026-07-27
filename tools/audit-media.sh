#!/usr/bin/env bash
# Report media health: repo size, per-page weight, unreferenced files,
# broken references, and anything over the MEDIA.md budgets.
set -uo pipefail
cd "$(git rev-parse --show-toplevel)"

SRC=$(git ls-files '*.md' '*.html' '*.yml')
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
cat $SRC > "$TMP/src.txt"

# media extensions only — keeps inline code spans like `assets/config.py` out of the results
EXT='jpg|jpeg|png|gif|webp|svg|mp4|webm|mov|MOV|pdf|HEIC'

# every asset path referenced from source, percent-decoded
grep -rhoE "(/?assets/[^\")'>\`]+\.($EXT))" $SRC \
  | sed 's|^/||' \
  | python3 -c 'import sys,urllib.parse;[print(urllib.parse.unquote(l.strip())) for l in sys.stdin]' \
  | sort -u > "$TMP/refs.txt"

echo "=== size ==="
printf "  worktree assets : %s\n" "$(du -sh assets 2>/dev/null | cut -f1)"
printf "  .git            : %s\n" "$(du -sh .git | cut -f1)"
printf "  tracked assets  : %d files\n" "$(git ls-files 'assets/*' | wc -l)"

echo
echo "=== broken references (linked but missing on disk) ==="
n=0
while read -r p; do
  [ -f "$p" ] || { echo "  MISSING  $p"; n=$((n+1)); }
done < "$TMP/refs.txt"
[ "$n" -eq 0 ] && echo "  none"

echo
echo "=== unreferenced assets (on disk, never linked) ==="
n=0
while read -r f; do
  b=$(basename "$f")
  enc=$(python3 -c 'import urllib.parse,sys;print(urllib.parse.quote(sys.argv[1]))' "$b")
  if ! grep -qF -- "$b" "$TMP/src.txt" && ! grep -qF -- "$enc" "$TMP/src.txt"; then
    printf "  %7s  %s\n" "$(du -h "$f" | cut -f1)" "$f"; n=$((n+1))
  fi
done < <(git ls-files 'assets/*')
[ "$n" -eq 0 ] && echo "  none"

echo
echo "=== over budget (image >500 KB, video >12 MB) ==="
n=0
while read -r f; do
  sz=$(stat -c%s "$f" 2>/dev/null) || continue
  case "${f##*.}" in
    mp4|webm|mov) lim=12582912 ;;
    jpg|jpeg|png|gif|webp) lim=512000 ;;
    *) continue ;;
  esac
  [ "$sz" -gt "$lim" ] && { printf "  %7s  %s\n" "$(du -h "$f" | cut -f1)" "$f"; n=$((n+1)); }
done < <(git ls-files 'assets/*')
[ "$n" -eq 0 ] && echo "  none"

echo
echo "=== page weight: initial load / total if every video is played ==="
echo "    (videos marked preload=\"none\" cost only their poster until clicked)"
for f in $(git ls-files '*.md'); do
  python3 - "$f" <<'PY'
import re, os, sys, urllib.parse
f = sys.argv[1]
s = open(f, encoding='utf-8').read()
EXT = r'jpg|jpeg|png|gif|webp|svg|mp4|webm|mov|pdf'

def size(p):
    p = urllib.parse.unquote(p).lstrip('/')
    return os.path.getsize(p) if os.path.isfile(p) else 0

# videos that defer until the user clicks
lazy = set()
for m in re.finditer(r'<video([^>]*)>(.*?)</video>', s, re.S | re.I):
    attrs, body = m.group(1), m.group(2)
    if 'preload="none"' not in attrs:
        continue
    for src in re.findall(r'src="([^"]+\.mp4)"', attrs + body):
        lazy.add(urllib.parse.unquote(src).lstrip('/'))

refs = {urllib.parse.unquote(p).lstrip('/')
        for p in re.findall(rf'/?assets/[^"\')>`]+\.(?:{EXT})', s)}
total = sum(size(p) for p in refs)
initial = sum(size(p) for p in refs if p not in lazy)
if total > 1048576:
    flag = '   <-- initial load over 25 MB budget' if initial > 26214400 else ''
    print(f"{initial:12d}|  {initial/1048576:6.1f} MB initial /{total/1048576:7.1f} MB total  {f}{flag}")
PY
done | sort -rn | cut -d'|' -f2

exit 0
