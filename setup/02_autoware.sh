#!/usr/bin/env bash
# Marco [4] do runbook: instala o Autoware Universe (via Docker) + prepara pasta de mapa.
# Uso:  bash setup/02_autoware.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

have git || die "git não encontrado (sudo apt-get install -y git)."

log "1/3 · Clonar Autoware em ${AUTOWARE_ROOT}"
if [[ -d "${AUTOWARE_ROOT}/.git" ]]; then
  ok "já clonado"
else
  git clone https://github.com/autowarefoundation/autoware.git "${AUTOWARE_ROOT}"
fi

log "2/3 · setup-dev-env (docker): rocker + dependências de container"
cd "${AUTOWARE_ROOT}"
./setup-dev-env.sh -y docker

log "3/3 · Pasta de mapas"
mkdir -p "${AUTOWARE_MAP}"
ok "Criada ${AUTOWARE_MAP}"

cat <<EOF

Próximos passos manuais (ver docs/SETUP-AWS-FASE0.md §4):
  • Baixe o mapa de exemplo (sample-map-planning) para ${AUTOWARE_MAP}
  • Suba o container:   bash scripts/run_autoware.sh
  • Smoke test no rviz2 (via NICE DCV): planning_simulator SEM CARLA
Marco [4] validado quando o planning simulator abrir no rviz2. Depois: bash setup/03_carla.sh
EOF
