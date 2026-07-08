#!/usr/bin/env bash
# Sobe o CARLA headless em Docker (render off-screen via Vulkan, GPU via nvidia-toolkit).
# --net=host: mesmo espaço de rede do container do Autoware e do TAP. Marco [5]/[7].
# Uso:  bash scripts/run_carla.sh   (Ctrl+C para parar)
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../setup" && pwd)/lib.sh"

have docker || die "docker não encontrado."
docker rm -f carla-server >/dev/null 2>&1 || true
log "CARLA ${CARLA_VERSION} (Docker) headless em ${CARLA_HOST}:${CARLA_PORT}"
exec docker run --rm --name carla-server --gpus all --net=host \
  "${CARLA_IMAGE}" ./CarlaUE4.sh -RenderOffScreen -quality-level=Low -nosound
