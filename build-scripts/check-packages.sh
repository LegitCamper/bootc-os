#!/usr/bin/env bash
# Resolve every name in packages.sh against the configured repos without
# installing anything. Catches typos, F-version drift (e.g. ipp-usb is F44+)
# and packages that vanished from a COPR — at PR time instead of mid-build.
#
# Run inside the build container after dnf.sh has enabled the repos:
#   bash /ctx/check-packages.sh
set -euo pipefail

cd "$(dirname "$0")"

# Reuse the real list rather than duplicating it: take the first packages=()
# array (the install one; a later array holds the removals).
mapfile -t names < <(
  awk '/^packages=\(/{f=1;next} f&&/^\)/{exit} f' packages.sh \
    | sed 's/#.*//' \
    | tr -d ' \t' \
    | grep -v '^$'
)

(( ${#names[@]} )) || { echo "parsed 0 packages — parser is broken" >&2; exit 1; }
echo "Checking ${#names[@]} package names..."

missing=()
for n in "${names[@]}"; do
  if [[ $n == @* ]]; then
    dnf5 -q group info "${n#@}" >/dev/null 2>&1 || missing+=("$n")
  else
    dnf5 -q list --available --installed "$n" >/dev/null 2>&1 || missing+=("$n")
  fi
done

if (( ${#missing[@]} )); then
  printf 'UNRESOLVABLE: %s\n' "${missing[@]}" >&2
  exit 1
fi

echo "All package names resolve."
