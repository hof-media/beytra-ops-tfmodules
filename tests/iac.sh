#!/bin/bash
# Module Validation for beytra-ops-tfmodules
# Validates every shared terraform module in the repo compiles correctly.

PASSED=0
FAILED=0

echo "=========================================="
echo "Module Validation: beytra-ops-tfmodules"
echo "=========================================="

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULES_DIR="$SCRIPT_DIR/../modules"

for mod in "$MODULES_DIR"/*/; do
  name=$(basename "$mod")
  echo -e "\n🔍 Testing: module $name validates"

  if (cd "$mod" && terraform init -backend=false >/dev/null 2>&1 && terraform validate >/dev/null 2>&1); then
    echo "   ✅ PASSED"
    PASSED=$((PASSED + 1))
  else
    echo "   ❌ FAILED"
    (cd "$mod" && terraform validate 2>&1 | head -3)
    FAILED=$((FAILED + 1))
  fi
done

echo ""
echo "=========================================="
echo "Passed: $PASSED"
echo "Failed: $FAILED"
echo "=========================================="

if [ $FAILED -gt 0 ]; then
  echo "❌ TESTS FAILED"
  exit 1
else
  echo "✅ ALL TESTS PASSED"
  exit 0
fi
