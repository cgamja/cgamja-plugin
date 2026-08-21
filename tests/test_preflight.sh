P=skills/develop-setup/scripts/preflight.sh
E=$(mktemp -d); out="$(bash $P $E)"; check "empty dir → exit 1" "✗ 항목" "$out"
check "empty dir → no design section" "" "$(grep '디자인' <<<"$out")"
mkdir -p $E/design; out="$(bash $P $E)"; check "design/ without marker → shows design rows" "design/tokens.json" "$out"
touch $E/design/NO_FIGMA; check "design/NO_FIGMA → hides design" "" "$(bash $P $E | grep '디자인')"
check "api 계약 rows present" "orval.config.ts" "$(bash $P $E)"
