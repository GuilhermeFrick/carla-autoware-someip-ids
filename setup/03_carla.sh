#!/usr/bin/env bash
# Marco [5] do runbook: baixa e prepara o CARLA (versão pinada em config/env.sh) + API Python.
# Uso:  bash setup/03_carla.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

tarball="CARLA_${CARLA_VERSION}.tar.gz"
url="https://github.com/carla-simulator/carla/releases/download/${CARLA_VERSION}/${tarball}"

log "1/3 · Baixar/extrair CARLA ${CARLA_VERSION} em ${CARLA_ROOT}"
mkdir -p "${CARLA_ROOT}"; cd "${CARLA_ROOT}"
if [[ -f CarlaUE4.sh ]]; then
  ok "CARLA já extraído"
else
  [[ -f "${tarball}" ]] || wget -O "${tarball}" "${url}"
  tar -xzf "${tarball}"
fi

log "2/3 · Dependências de render (Vulkan)"
sudo apt-get update && sudo apt-get install -y libvulkan1 vulkan-tools

log "3/3 · API Python do CARLA"
python3 -m pip install "carla==${CARLA_VERSION}" \
  && ok "pip carla==${CARLA_VERSION} instalado" \
  || warn "pip carla falhou — confira a versão do Python (o egg do 0.9.15 casa com 3.7–3.10). Use venv se preciso."

cat <<EOF

Teste (marco [5]):
  • Terminal A:  bash scripts/run_carla.sh
  • Terminal B:  python3 ${CARLA_ROOT}/PythonAPI/examples/generate_traffic.py -n 10
Deve conectar em ${CARLA_HOST}:${CARLA_PORT}. Cole o log do CarlaUE4.sh se houver erro de Vulkan.
Depois: bash setup/04_bridge.sh
EOF
