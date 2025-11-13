#!/usr/bin/env bash
set -euo pipefail
PROJ="iSIF_Beta.xcodeproj/project.pbxproj"
dup=0

# Must NOT appear in Compile Sources
if grep -q "xcstrings in Sources" "$PROJ" ; then
  echo "❌ One or more .xcstrings are in Compile Sources. Move them to Copy Bundle Resources."
  dup=1
fi

# Each catalog must appear exactly once in Copy Bundle Resources
for name in DeliveryType.xcstrings SIFRecipient.xcstrings; do
  count=$(grep -c "$name in Resources" "$PROJ" || true)
  if [ "${count:-0}" -gt 1 ]; then
    echo "❌ Duplicate entry for $name in Copy Bundle Resources ($count)"
    dup=1
  fi
done

if [ "$dup" -ne 0 ]; then exit 1; fi
echo "✅ Localization catalogs OK"
