#!/usr/bin/env bash
# Marco [8a]: desktop virtual (Xvfb) + VNC (x11vnc) + WM (fluxbox) no host, para VER o rviz do
# Autoware numa VM headless. Usa software GL (simples/confiável); se ficar pesado com a nuvem de
# pontos, migra-se para VirtualGL/GPU depois. Acesso seguro: VNC só em localhost + túnel SSH.
# Idempotente: se já estiver rodando, não sobe de novo.
# Uso:  bash setup/07_desktop.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

DISP="${VNC_DISPLAY:-:99}"
PORT="${VNC_PORT:-5900}"
RES="${VNC_RES:-1920x1080x24}"

log "1/2 · Dependências (xvfb, x11vnc, fluxbox)"
if ! have Xvfb || ! have x11vnc || ! have fluxbox; then
  sudo apt-get update && sudo apt-get install -y xvfb x11vnc fluxbox
else
  ok "já instaladas"
fi

log "2/2 · Subir Xvfb ${DISP} + fluxbox + x11vnc (porta ${PORT}, só localhost, sem senha)"
# nohup = sobrevive à queda da sessão SSH (não morre com SIGHUP).
pgrep -f "Xvfb ${DISP}"    >/dev/null || { nohup Xvfb "${DISP}" -screen 0 "${RES}" >/tmp/xvfb.log 2>&1 & sleep 2; }
pgrep -f "fluxbox"         >/dev/null || { nohup env DISPLAY="${DISP}" fluxbox >/tmp/fluxbox.log 2>&1 & sleep 1; }
pgrep -f "x11vnc.*${PORT}" >/dev/null || { nohup x11vnc -display "${DISP}" -forever -shared -localhost -nopw -rfbport "${PORT}" >/tmp/x11vnc.log 2>&1 & sleep 2; }

echo
jobs 2>/dev/null || true
ok "Desktop no ${DISP} · VNC em localhost:${PORT}"
cat <<EOF

Acessar do seu PC:
  1) túnel SSH:   ssh -i ~/.ssh/SUA_CHAVE -L ${PORT}:localhost:${PORT} <user>@<IP_DA_VM>
  2) cliente VNC (TigerVNC/RealVNC) → localhost:${PORT}  → aparece o desktop cinza (fluxbox)
Depois, com o CARLA rodando (make run-carla), suba o Autoware com rviz:
  RVIZ=true make run-autoware
Logs: /tmp/xvfb.log  /tmp/fluxbox.log  /tmp/x11vnc.log
Parar o desktop:  pkill x11vnc; pkill fluxbox; pkill Xvfb
EOF
