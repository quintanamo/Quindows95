#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

SOURCE_DIR="${1:-$REPO_ROOT/dos-programs/hackman}"
OUTPUT_DIR="${2:-$REPO_ROOT/public/applications}"
PROGRAM_NAME="$(basename "$SOURCE_DIR" | tr '[:lower:]' '[:upper:]')"
OUTPUT_FILE="$OUTPUT_DIR/$PROGRAM_NAME.jsdos"

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

EXECUTABLES=()
while IFS= read -r -d '' FILE; do
EXECUTABLES+=("$FILE")
done < <(find "$SOURCE_DIR" -type f -iname '*.exe' -print0)

if [[ "${#EXECUTABLES[@]}" -ne 1 ]]; then
echo "ERROR: Expected exactly one .EXE file in the source directory tree; found ${#EXECUTABLES[@]}:"
find "$SOURCE_DIR" -type f -iname '*.exe' -print
exit 1
fi

EXECUTABLE_RELATIVE_PATH="${EXECUTABLES[0]#"$SOURCE_DIR"/}"
EXECUTABLE_DIRECTORY="$(dirname "$EXECUTABLE_RELATIVE_PATH")"
EXECUTABLE_NAME="$(basename "$EXECUTABLE_RELATIVE_PATH")"

mkdir -p "$OUTPUT_DIR"

STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT

echo "Packing $PROGRAM_NAME..."
echo "Source: $SOURCE_DIR"
echo "Output: $OUTPUT_FILE"

cp -R "$SOURCE_DIR/." "$STAGE/"
mkdir -p "$STAGE/.jsdos"

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
EOF

if [[ "$EXECUTABLE_DIRECTORY" != "." ]]; then
printf 'cd "%s"\n' "$EXECUTABLE_DIRECTORY" >> "$STAGE/.jsdos/dosbox.conf"
fi

printf '%s\n' "$EXECUTABLE_NAME" >> "$STAGE/.jsdos/dosbox.conf"

printf '%s\n' '{"version":"8.4.1"}' > "$STAGE/.jsdos/jsdos.json"

echo
echo "Creating bundle..."

rm -f "$OUTPUT_FILE"

(
cd "$STAGE"
zip -r -X "$OUTPUT_FILE" . -x ".DS_Store" "__MACOSX*" "/._"
)

if [[ ! -f "$OUTPUT_FILE" ]]; then
echo "ERROR: Bundle was not created."
exit 1
fi

echo
echo "Verifying bundle..."

ZIP_LIST="$(unzip -l "$OUTPUT_FILE")"

if ! printf '%s\n' "$ZIP_LIST" | grep -qF "$EXECUTABLE_RELATIVE_PATH"; then
echo "ERROR: $EXECUTABLE_RELATIVE_PATH is missing from the bundle."
exit 1
fi

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