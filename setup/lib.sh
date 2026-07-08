#!/usr/bin/env bash
# Helpers compartilhados pelos scripts de setup/ e scripts/. Não executar direto.
set -euo pipefail

# Raiz do repo (este arquivo vive em setup/)
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export REPO_ROOT

# Carrega config/env.sh (local) ou, na ausência, o exemplo versionado.
if [[ -f "${REPO_ROOT}/config/env.sh" ]]; then
  # shellcheck disable=SC1091
  source "${REPO_ROOT}/config/env.sh"
else
  # shellcheck disable=SC1091
  source "${REPO_ROOT}/config/env.example.sh"
fi

log()  { printf '\n\033[1;34m[SETUP]\033[0m %s\n' "$*"; }
ok()   { printf '\033[1;32m  ✓ \033[0m%s\n' "$*"; }
warn() { printf '\033[1;33m  ! \033[0m%s\n' "$*"; }
die()  { printf '\n\033[1;31m[ERRO]\033[0m %s\n' "$*" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }
