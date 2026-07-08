#!/usr/bin/env bash
# Sobe o CARLA headless (render off-screen via Vulkan). Marco [5]/[7].
# Uso:  bash scripts/run_carla.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../setup" && pwd)/lib.sh"

[[ -f "${CARLA_ROOT}/CarlaUE4.sh" ]] || die "CARLA não encontrado em ${CARLA_ROOT}. Rode setup/03_carla.sh"
cd "${CARLA_ROOT}"
log "CARLA ${CARLA_VERSION} headless em ${CARLA_HOST}:${CARLA_PORT} (Ctrl+C para parar)"
exec ./CarlaUE4.sh -RenderOffScreen -quality-level=Low -nosound
