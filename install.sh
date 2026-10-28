#!/bin/sh
# Links Coordinator into Claude Code from this checkout, so `git pull` updates it.
#   coord        -> $COORD_BIN_DIR (default ~/.local/bin)
#   /coordinate  -> ~/.claude/skills/coordinate
set -e
ROOT="$(cd "$(dirname "$0")" && pwd)"
BIN="${COORD_BIN_DIR:-$HOME/.local/bin}"
SKILLS="$HOME/.claude/skills"

command -v python3 >/dev/null || { echo "Coordinator needs python3" >&2; exit 1; }
command -v claude >/dev/null || echo "warning: the claude CLI is not on PATH; agents can't start without it" >&2

mkdir -p "$BIN" "$SKILLS"
chmod +x "$ROOT/bin/coord"
ln -sfn "$ROOT/bin/coord" "$BIN/coord"

if [ -e "$SKILLS/coordinate" ] && [ ! -L "$SKILLS/coordinate" ]; then
  echo "$SKILLS/coordinate already exists and is not a link to Coordinator; move it away, then run this again" >&2
  exit 1
fi
ln -sfn "$ROOT/skills/coordinate" "$SKILLS/coordinate"

case ":$PATH:" in
  *":$BIN:"*) ;;
  *) echo "note: add $BIN to your PATH" ;;
esac
echo "Coordinator installed: coord -> $BIN/coord, /coordinate -> $SKILLS/coordinate"
