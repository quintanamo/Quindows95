#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

SOURCE_DIR="${1:-$REPO_ROOT/dos-programs/hackman}"
OUTPUT_DIR="${2:-$REPO_ROOT/public/applications}"
OUTPUT_FILE="$OUTPUT_DIR/HACKMAN.jsdos"

if [[ ! -d "$SOURCE_DIR" ]]; then
echo "ERROR: Source directory does not exist:"
echo "$SOURCE_DIR"
exit 1
fi

if ! command -v zip >/dev/null 2>&1; then
echo "ERROR: zip is not installed."
exit 1
fi

if ! command -v unzip >/dev/null 2>&1; then
echo "ERROR: unzip is not installed."
exit 1
fi

REQUIRED_FILES=(
"HACKMAN.EXE"
"EASY.HCK"
"MEDIUM.HCK"
"HARD.HCK"
"EXPERT.HCK"
"INSANE.HCK"
)

for FILE in "${REQUIRED_FILES[@]}"; do
if [[ ! -f "$SOURCE_DIR/$FILE" ]]; then
echo "ERROR: Missing required file:"
echo "$SOURCE_DIR/$FILE"
exit 1
fi
done

mkdir -p "$OUTPUT_DIR"

STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT

echo "Packing HACKMAN..."
echo "Source: $SOURCE_DIR"
echo "Output: $OUTPUT_FILE"

mkdir -p "$STAGE/.jsdos"

for FILE in "${REQUIRED_FILES[@]}"; do
cp "$SOURCE_DIR/$FILE" "$STAGE/$FILE"
done

cat > "$STAGE/.jsdos/dosbox.conf" <<'EOF'
[sdl]
autolock=false

[dosbox]
machine=svga_s3
memsize=16

[cpu]
core=auto
cputype=auto
cycles=3000

[render]
frameskip=0
aspect=false
scaler=none

[mixer]
nosound=false
rate=44100

[sblaster]
sbtype=sb16
sbmixer=true
oplmode=auto

[speaker]
pcspeaker=true

[autoexec]
@echo off
mount c .
c:
HACKMAN.EXE
EOF

printf '%s\n' '{"version":"8.4.1"}' > "$STAGE/.jsdos/jsdos.json"

echo
echo "Creating bundle..."

rm -f "$OUTPUT_FILE"

(
cd "$STAGE"
zip -r -X "$OUTPUT_FILE" .
-x ".DS_Store"
-x "__MACOSX*"
-x "/._"
)

if [[ ! -f "$OUTPUT_FILE" ]]; then
echo "ERROR: Bundle was not created."
exit 1
fi

echo
echo "Verifying bundle..."

ZIP_LIST="$(unzip -l "$OUTPUT_FILE")"

for FILE in "${REQUIRED_FILES[@]}"; do
if ! printf '%s\n' "$ZIP_LIST" | grep -qE "[[:space:]]${FILE}$"; then
echo "ERROR: $FILE is missing from the bundle."
exit 1
fi
done

if ! printf '%s\n' "$ZIP_LIST" | grep -qF ".jsdos/dosbox.conf"; then
echo "ERROR: .jsdos/dosbox.conf is missing."
exit 1
fi

if ! printf '%s\n' "$ZIP_LIST" | grep -qF ".jsdos/jsdos.json"; then
echo "ERROR: .jsdos/jsdos.json is missing."
exit 1
fi

echo
echo "Bundle created successfully:"
echo "$OUTPUT_FILE"
echo
echo "Bundle contents:"
unzip -l "$OUTPUT_FILE"