#!/usr/bin/env bash
set -euo pipefail

backup_once() {
  local file="$1"
  local bak="${file}.bak"
  [[ -e "$bak" ]] || cp -a "$file" "$bak"
}

repair_file() {
  local primary="$1"
  local shadow="$2"
  local mode="$3"

  [[ -f "$primary" && -f "$shadow" ]] || return 0

  local tmp
  local changed=0
  tmp="$(mktemp)"

  while IFS= read -r line; do
    name="${line%%:*}"
    [[ -n "$name" ]] || continue

    if grep -q "^${name}:" "$primary"; then
      printf '%s\n' "$line" >>"$tmp"
    else
      echo "Removing orphaned ${shadow} entry: ${name}"
      changed=1
    fi
  done <"$shadow"

  if [[ $changed -eq 1 ]]; then
    backup_once "$shadow"
    install -m "$mode" -o root -g root "$tmp" "$shadow"
  fi

  rm -f "$tmp"
}

repair_file /etc/group /etc/gshadow 0400
repair_file /etc/passwd /etc/shadow 0000
