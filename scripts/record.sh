#!/usr/bin/env bash
# Grava o desktop :99 (rviz) num MP4 NO SERVIDOR — vídeo liso, independente do lag do VNC/streaming.
# Faça os cliques pelo VNC (Initialize GNSS -> Goal -> Auto); esta gravação sai fluida.
# Uso:   bash scripts/record.sh [saida.mp4]     (Ctrl+C para parar)
# Baixar depois no PC:  scp -i ~/.ssh/carla_gpu2 ubuntu@<IP>:<saida.mp4> .
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../setup" && pwd)/lib.sh"

DISP="${VNC_DISPLAY:-:99}"
RES="${VNC_RES:-1920x1080x24}"; RES="${RES%x*}"     # 1920x1080
OUT="${1:-${HOME}/fase0_$(date +%Y%m%d_%H%M%S).mp4}"

have ffmpeg || { sudo apt-get update && sudo apt-get install -y ffmpeg; }

log "Gravando ${DISP} (${RES}) → ${OUT}"
echo "   (Ctrl+C para parar. Depois baixe com scp.)"
exec ffmpeg -y -f x11grab -framerate 30 -video_size "${RES}" -i "${DISP}" \
  -c:v libx264 -preset veryfast -pix_fmt yuv420p "${OUT}"
