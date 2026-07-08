#!/usr/bin/env bash
# Marco [5] do runbook: prepara o CARLA em Docker (imagem oficial carlasim/carla).
# NADA é instalado no host — o servidor roda no container, com Python próprio (resolve
# o mismatch do Ubuntu 24.04). Uso:  bash setup/03_carla.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

have docker || die "docker não encontrado. Rode: bash setup/01_base_deps.sh (ou use a DLAMI)."

log "1/2 · Baixar imagem ${CARLA_IMAGE}"
docker pull "${CARLA_IMAGE}"

log "2/2 · Smoke test — sobe o servidor headless por ~15s e mostra o log"
docker rm -f carla-smoke >/dev/null 2>&1 || true
docker run -d --rm --name carla-smoke --gpus all --net=host \
  "${CARLA_IMAGE}" ./CarlaUE4.sh -RenderOffScreen -quality-level=Low -nosound
sleep 15
echo "──────── log do CARLA (procure a versão 0.9.15 e ausência de erro de Vulkan) ────────"
docker logs carla-smoke 2>&1 | tail -30 || true
docker stop carla-smoke >/dev/null 2>&1 || true

cat <<EOF

Marco [5] OK se o log acima não mostrou erro de Vulkan/GPU.
Uso normal:
  • bash scripts/run_carla.sh          (ou: docker compose up carla)
Teste de cliente (a própria imagem tem a PythonAPI compatível):
  • bash scripts/run_carla.sh          # deixa o servidor rodando
  • docker run --rm --net=host ${CARLA_IMAGE} \\
      python3 PythonAPI/examples/generate_traffic.py -n 10 --host 127.0.0.1
Depois: bash setup/04_bridge.sh
EOF
