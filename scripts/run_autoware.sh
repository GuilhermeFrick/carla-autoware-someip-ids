#!/usr/bin/env bash
# Entra no container do Autoware (com GPU + X para o rviz2 via NICE DCV). Marco [4]/[7].
# Uso:  bash scripts/run_autoware.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../setup" && pwd)/lib.sh"

[[ -d "${AUTOWARE_ROOT}" ]] || die "Autoware não encontrado em ${AUTOWARE_ROOT}. Rode setup/02_autoware.sh"
cd "${AUTOWARE_ROOT}"
log "Abrindo container do Autoware (map-path=${AUTOWARE_MAP})"
exec ./docker/run.sh --map-path "${AUTOWARE_MAP}"
