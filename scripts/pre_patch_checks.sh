#!/usr/bin/env bash
set -e
# duplicate type check
dup=$(grep -RhoE '^(public )?(struct|enum|class) +[A-Za-z_][A-Za-z0-9_]*' Sources \
      | sed -E 's/^(public )?(struct|enum|class) +//' \
      | sort | uniq -d)
[ -z "$dup" ] || { echo "Duplicate types: $dup"; exit 1; }
# cyclic import
swift package describe --type json | grep -q '"cycle"' && { echo "Import cycle"; exit 1; }
# legacy shared
grep -R 'TunaSettings\\.shared' Sources && { echo "Found shared singleton"; exit 1; } 