#!/bin/bash

VERFILE="version.scad"

if [[ "$(cat "$VERFILE")" =~  BOSL_VERSION.*=.*\[([0-9]+),\ *([0-9]+),\ *([0-9]+)\]\; ]]; then
  major=${BASH_REMATCH[1]} minor=${BASH_REMATCH[2]} revision=${BASH_REMATCH[3]}
  new_revision=$(( revision+1 ))

  echo "Current Version: $major.$minor.$revision"
  echo "New Version: $major.$minor.$new_revision"

  sed -i.bak -e 's/^BOSL_VERSION = .*$/BOSL_VERSION = ['"$major,$minor,$new_revision];/g" "$VERFILE"
  rm "$VERFILE".bak
else
  echo "Could not extract version number from $VERFILE" >&2
  exit 1
fi
