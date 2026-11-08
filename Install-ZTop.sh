#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
set -uo pipefail
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
log="${HOME}/ztop-install-$(date +%Y%m%d-%H%M%S).log"
bash "$ROOT/tools/install.sh" 2>&1 | tee "$log"
rc=${PIPESTATUS[0]}
if command -v dialog >/dev/null && [[ -t 0 ]]; then
  if [[ $rc == 0 ]]; then msg="ZTop R2 instalado. Reinicie pelo menu. Log: $log"; else msg="Instalacao cancelada ou falhou. Consulte: $log"; fi
  dialog --clear --timeout 15 --ok-label 'Voltar / Back' --msgbox "$msg" 10 65 || true
fi
exit "$rc"
