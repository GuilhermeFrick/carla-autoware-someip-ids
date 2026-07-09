#!/usr/bin/env bash
# Marco [4]: baixa a imagem PRÉ-BUILDADA do Autoware (universe-cuda) e confirma que a
# interface CARLA vem nela. NÃO clona o Autoware nem roda setup-dev-env — o fluxo é
# 100% Docker com a imagem pronta. Uso:  bash setup/02_autoware.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

have docker || die "docker não encontrado."

log "1/2 · Baixar imagem do Autoware: ${AUTOWARE_IMAGE} (grande, ~vários GB)"
docker pull "${AUTOWARE_IMAGE}"

log "2/2 · Conferir se a interface CARLA está na imagem"
if docker run --rm "${AUTOWARE_IMAGE}" bash -lc 'ros2 pkg list | grep -i carla'; then
  ok "Pacotes CARLA presentes (autoware_carla_interface + carla_sensor_kit)."
else
  warn "Não achei pacotes carla na imagem — me avise (a tag pode ter mudado)."
fi

log "Marco [4] OK. Próximo: bash setup/05_map.sh (mapa do Town01)"
