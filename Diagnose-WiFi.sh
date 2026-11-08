#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
set -uo pipefail
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
python3 "$ROOT/tools/diagnose.py" "$@"
rc=$?
if command -v dialog >/dev/null && [[ -t 0 ]]; then
  dialog --clear --timeout 15 --ok-label 'Voltar / Back' --msgbox 'Diagnostico finalizado. Logs em ~/ztop-diagnostics. Revise os dados antes de compartilhar.' 10 65 || true
fi
exit "$rc"
