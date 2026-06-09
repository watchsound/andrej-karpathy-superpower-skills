#!/usr/bin/env bash
# sync-skills.sh — idempotent skill-symlink sync for macOS/Linux.
#
# Creates a symlink in ~/.claude/skills/ for every skill in this repo that
# does not already have one. Existing links (valid or broken) are left
# alone. Safe to re-run after every `git pull` to pick up new skills.
#
# Usage (from anywhere):
#   bash ./sync-skills.sh
#   # or, after chmod +x sync-skills.sh:
#   ./sync-skills.sh

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
src="$script_dir/skills"
dst="$HOME/.claude/skills"

if [ ! -d "$src" ]; then
  echo "Skills source dir not found: $src" >&2
  echo "Run this script from inside the repo." >&2
  exit 1
fi

mkdir -p "$dst"

created=0
for d in "$src"/*/; do
  name="$(basename "$d")"
  link="$dst/$name"
  # Skip if anything (valid link, broken link, or real dir) already at $link.
  if [ ! -e "$link" ] && [ ! -L "$link" ]; then
    ln -s "$(cd "$d" && pwd)" "$link"
    echo "Created symlink: $name"
    created=$((created + 1))
  fi
done

if [ "$created" -eq 0 ]; then
  echo "All skills already linked. Nothing to do."
else
  echo "$created symlink(s) created in $dst"
fi
