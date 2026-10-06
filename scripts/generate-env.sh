#!/bin/sh
set -eu
umask 077

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
template="$script_dir/../k8s/env.example"
output=${1:-/root/apps/findee/envs/env.prod}

if [ ! -f "$template" ]; then
  echo "Environment template not found: $template" >&2
  exit 1
fi
output_dir=$(dirname -- "$output")
mkdir -p "$output_dir"

additions=$(mktemp "$output_dir/env.prod.tmp.XXXXXX")
trap 'rm -f "$additions"' EXIT
trap 'exit 1' HUP INT TERM

if [ -e "$output" ]; then
  # Preserve existing values, including empty ones; append only missing keys.
  awk '
    function key(line) {
      sub(/^[[:space:]]*(export[[:space:]]+)?/, "", line)
      if (line !~ /^[A-Za-z_][A-Za-z0-9_]*[[:space:]]*=/) return ""
      sub(/[[:space:]]*=.*/, "", line)
      return line
    }
    FILENAME == ARGV[1] {
      name=key($0)
      if (name != "") present[name]=1
      next
    }
    {
      name=key($0)
      if (name != "" && !(name in present)) {
        print
        present[name]=1
      }
    }
  ' "$output" "$template" > "$additions"
  if [ ! -s "$additions" ]; then
    echo "No missing variables: $output"
    exit 0
  fi
  printf '\n' >> "$output"
  cat "$additions" >> "$output"
  echo "Added missing variables: $output"
else
  cat "$template" > "$additions"
  if ! ln "$additions" "$output" 2>/dev/null; then
    echo "Could not create $output; no existing file was overwritten." >&2
    exit 1
  fi
  echo "Generated environment: $output"
fi
