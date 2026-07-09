#!/usr/bin/env bash
# rviz do Autoware renderizado na GPU (VirtualGL/EGL) e exibido no desktop VNC (:99).
# Use quando o rviz em software GL (RVIZ=true make run-autoware) estiver lento demais.
# Fluxo:
#   term1: make run-carla
#   term2: make run-autoware        # headless (SEM RVIZ) — só a autonomia
#   term3: make rviz                # este script: rviz na GPU, na janela VNC
# Requer: desktop VNC no ar (make desktop). Uso:  bash scripts/run_rviz.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../setup" && pwd)/lib.sh"

have docker || die "docker não encontrado."
IMG="carla-aw-rviz-vgl"

if ! docker image inspect "${IMG}" >/dev/null 2>&1; then
  log "Build da imagem rviz+VirtualGL (uma vez)"
  docker build -t "${IMG}" -f "${REPO_ROOT}/docker/rviz-vgl.Dockerfile" "${REPO_ROOT}"
fi

log "rviz na GPU (VirtualGL/EGL) → DISPLAY ${VNC_DISPLAY:-:99} (janela VNC)"
# NVIDIA_DRIVER_CAPABILITIES=all: expõe as libs GRÁFICAS (GL/EGL) da NVIDIA no container.
# Sem isso o runtime só dá compute/utility (CUDA) e o VirtualGL cai para Mesa/llvmpipe (software).
exec docker run --rm -it --gpus all --net=host \
  -e NVIDIA_DRIVER_CAPABILITIES=all -e NVIDIA_VISIBLE_DEVICES=all \
  -e DISPLAY="${VNC_DISPLAY:-:99}" -e QT_X11_NO_MITSHM=1 \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  -v "${AUTOWARE_DATA}:/root/autoware_data" \
  "${IMG}" bash -lc '
    source /opt/autoware/setup.bash
    # teste rápido: vglrun -d egl glxinfo | grep -i "renderer" deve mostrar a A6000
    vglrun -d egl rviz2 -d /opt/autoware/share/autoware_launch/rviz/autoware.rviz
  '
