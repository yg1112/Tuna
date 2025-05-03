#!/usr/bin/env bash
set -euo pipefail
echo "🔎 scanning duplicates…"

dup=$(grep -RhoE '^(public )?(struct|enum|class|protocol|typealias|actor|extension) +[A-Za-z_][A-Za-z0-9_]*' Sources \
      | sed -E 's/^(public )?(struct|enum|class|protocol|typealias|actor|extension) +//' \
      | sort | uniq -d)

[ -z "$dup" ] && { echo "✅ No duplicates"; exit 0; }

rank() {
  case "$1" in
    *TunaCore*) echo 10;;
    *TunaAudio*) echo 20;;
    *TunaSpeech*) echo 30;;
    *TunaUI*) echo 40;;
    *Tuna/Models*) echo 50;;
    *TunaTypes*) echo 60;;
    *) echo 99;;
  esac
}

for t in $dup; do
  echo "🔁 $t"
  mapfile -t paths < <(grep -R --line-number "^(public )?(struct|enum|class|protocol|typealias|actor|extension) .*${t}" Sources | cut -d':' -f1 | sort -u)
  best=""
  bestScore=999
  for p in "${paths[@]}"; do
    kind=$(grep -m1 -E "^(public )?(struct|enum|class|protocol|typealias|actor|extension)" "$p" | awk '{print $2}')
    case $kind in struct|class) kw=1;; protocol) kw=2;; *) kw=3;; esac
    score=$((kw*100+$(rank "$p")))
    if (( score < bestScore )); then bestScore=$score; best=$p; fi
  done
  echo "   ✔ keep $best"
  for p in "${paths[@]}"; do [[ "$p" == "$best" ]] && continue; echo "   ✂ $p"; git rm -f "$p"; done
 done

echo "🛠 fixing orphan imports"
grep -R --null -l 'import .*Notifier' Sources | xargs -0 sed -i '' -E 's/^import .*Notifier$/import TunaCore/'
grep -R --null -l 'import .*SecureStore' Sources | xargs -0 sed -i '' -E 's/^import .*SecureStore$/import TunaCore/'

echo "🧪 pre-check"
./Scripts/pre_patch_checks.sh

echo "🏗  build & test"
./Scripts/verify.sh && echo "🎉 VERIFIED" 