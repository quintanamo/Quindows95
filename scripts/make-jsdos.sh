#!/usr/bin/env bash
# Pack each nested DOS .exe under dos-programs/ into a js-dos 8 bundle.
#
# Expected source layout:
#
#   dos-programs/
#   └── SomeGame/
#       ├── bin/
#       │   └── GAME.EXE
#       └── words/
#           ├── easy.txt
#           └── ...
#
# The resulting .jsdos archive contains:
#
#   .jsdos/dosbox.conf
#   .jsdos/jsdos.json
#   bin/GAME.EXE
#   words/easy.txt
#   ...
#
# The DOS program is launched from C:\bin, so paths such as:
#
#   ../words/easy.txt
#
# resolve correctly.
#
# Usage:
#   ./scripts/make-jsdos.sh
#   ./scripts/make-jsdos.sh [source-dir] [output-dir]

set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"

source_dir="${1:-$repo_root/dos-programs}"
output_dir="${2:-$repo_root/public/applications}"

if ! command -v zip >/dev/null 2>&1; then
  echo "zip is required but was not found in PATH." >&2
  exit 1
fi

if ! command -v unzip >/dev/null 2>&1; then
  echo "unzip is required but was not found in PATH." >&2
  exit 1
fi

if [[ ! -d "$source_dir" ]]; then
  echo "Source directory does not exist: $source_dir" >&2
  exit 1
fi

mkdir -p "$output_dir"

uppercase() {
  printf '%s' "$1" | tr '[:lower:]' '[:upper:]'
}

write_dosbox_conf() {
  local conf_path="$1"
  local exe_name="$2"

  cat >"$conf_path" <<EOF
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
cd \\bin
ver
dir
${exe_name}
EOF
}

pack_exe() {
  local exe_path="$1"

  local game_dir
  local game_root
  local exe_name
  local bundle_stem
  local bundle_path
  local stage

  game_dir="$(cd "$(dirname "$exe_path")" && pwd)"
  exe_name="$(basename "$exe_path")"

  #
  # The EXE must live in a bin directory.
  #
  if [[ "$(basename "$game_dir")" != "bin" ]]; then
    echo "ERROR: executable is not inside a bin directory:" >&2
    echo "       $exe_path" >&2
    echo "       Expected something like: SomeGame/bin/game.exe" >&2
    exit 1
  fi

  #
  # The game root is the directory containing bin/.
  #
  game_root="$(cd "$game_dir/.." && pwd)"

  #
  # words/ is expected alongside bin/.
  #
  if [[ ! -d "$game_root/words" ]]; then
    echo "ERROR: expected words directory was not found:" >&2
    echo "       $game_root/words" >&2
    echo "       The expected layout is:" >&2
    echo "         $game_root/bin/$exe_name" >&2
    echo "         $game_root/words/easy.txt" >&2
    exit 1
  fi

  bundle_stem="$(uppercase "${exe_name%.*}")"
  bundle_path="$output_dir/${bundle_stem}.jsdos"

  stage="$(mktemp -d "${TMPDIR:-/tmp}/jsdos.XXXXXX")"

  # Always clean up the temporary directory.
  trap 'rm -rf "$stage"' RETURN

  echo "----------------------------------------"
  echo "Packing: $exe_name"
  echo "Source:  $game_root"
  echo "Output:  $bundle_path"

  #
  # Create the DOS directory structure in the bundle.
  #
  mkdir -p "$stage/bin"
  mkdir -p "$stage/words"

  #
  # Copy everything from the source bin/ directory into bundle/bin/.
  #
  # This preserves any DLLs, data files, config files, etc. that the
  # executable may need alongside itself.
  #
  if command -v rsync >/dev/null 2>&1; then
    rsync -a \
      --exclude '.DS_Store' \
      --exclude '._*' \
      --exclude '__MACOSX' \
      --exclude '.jsdos' \
      --exclude '*.jsdos' \
      "$game_dir"/ "$stage/bin"/
  else
    cp -R "$game_dir"/. "$stage/bin"/

    find "$stage/bin" \
      \( \
        -name '.DS_Store' -o \
        -name '._*' -o \
        -name '__MACOSX' -o \
        -name '.jsdos' -o \
        -name '*.jsdos' \
      \) \
      -prune \
      -exec rm -rf {} + 2>/dev/null || true
  fi

  #
  # Copy the complete words/ directory into the bundle.
  #
  if command -v rsync >/dev/null 2>&1; then
    rsync -a \
      --exclude '.DS_Store' \
      --exclude '._*' \
      --exclude '__MACOSX' \
      --exclude '.jsdos' \
      --exclude '*.jsdos' \
      "$game_root/words"/ "$stage/words"/
  else
    cp -R "$game_root/words"/. "$stage/words"/

    find "$stage/words" \
      \( \
        -name '.DS_Store' -o \
        -name '._*' -o \
        -name '__MACOSX' -o \
        -name '.jsdos' -o \
        -name '*.jsdos' \
      \) \
      -prune \
      -exec rm -rf {} + 2>/dev/null || true
  fi

  #
  # Verify that the executable made it into bin/.
  #
  if [[ ! -f "$stage/bin/$exe_name" ]]; then
    echo "ERROR: executable was not copied into bundle:" >&2
    echo "       $stage/bin/$exe_name" >&2
    exit 1
  fi

  #
  # Verify that words/easy.txt exists.
  #
  if [[ ! -f "$stage/words/easy.txt" ]]; then
    echo "ERROR: required file was not copied into bundle:" >&2
    echo "       $stage/words/easy.txt" >&2
    exit 1
  fi

  #
  # Create js-dos configuration directory.
  #
  mkdir -p "$stage/.jsdos"

  #
  # Create DOSBox configuration.
  #
  write_dosbox_conf \
    "$stage/.jsdos/dosbox.conf" \
    "$exe_name"

  #
  # js-dos metadata.
  #
  printf '%s\n' '{"version":"8.4.1"}' \
    >"$stage/.jsdos/jsdos.json"

  #
  # Show the files that are actually going into the archive.
  #
  echo "Bundle contents:"
  (
    cd "$stage"
    find . -maxdepth 3 -type f -print | sort
  )

  #
  # Create the ZIP/js-dos bundle.
  #
  rm -f "$bundle_path"

  (
    cd "$stage"

    zip -r -X -q "$bundle_path" . \
      -x '*.DS_Store' \
      -x '*__MACOSX*' \
      -x '*/._*'
  )

  #
  # Verify the resulting archive contains the required files.
  #
  if ! unzip -l "$bundle_path" | grep -qF '.jsdos/dosbox.conf'; then
    echo "ERROR: generated bundle does not contain .jsdos/dosbox.conf" >&2
    exit 1
  fi

  if ! unzip -l "$bundle_path" | grep -qF "bin/$exe_name"; then
    echo "ERROR: generated bundle does not contain bin/$exe_name" >&2
    exit 1
  fi

  if ! unzip -l "$bundle_path" | grep -qF 'words/easy.txt'; then
    echo "ERROR: generated bundle does not contain words/easy.txt" >&2
    exit 1
  fi

  echo "Wrote $bundle_path"
  echo "Launches: C:\\bin\\$exe_name"
  echo "----------------------------------------"
}

count=0

while IFS= read -r -d '' exe_path; do
  case "$exe_path" in
    */__MACOSX/*)
      continue
      ;;
  esac

  pack_exe "$exe_path"
  count=$((count + 1))
done < <(
  find "$source_dir" \
    -type f \
    -iname '*.exe' \
    ! -path '*/__MACOSX/*' \
    -print0
)

if [[ "$count" -eq 0 ]]; then
  echo "No .exe files found under $source_dir" >&2
  exit 1
fi

echo "Packed $count bundle(s) into $output_dir"
