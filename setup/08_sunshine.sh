#!/usr/bin/env bash
# Marco [8c]: streaming de BAIXA LATÊNCIA do rviz com Sunshine (usa o NVENC da GPU) + Moonlight.
# Muito mais fluido que VNC. Rede via Tailscale (privada, sem abrir firewall, estável ao trocar
# de WiFi). Captura o desktop virtual :99 (do make desktop, onde roda o make rviz).
# Uso:  bash setup/08_sunshine.sh   (depois: parear o Moonlight — instruções no fim)
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

DISP="${VNC_DISPLAY:-:99}"
# deb do Sunshine para Ubuntu 24.04 (host da VM). Ajuste a versão se sair release novo.
SUN_DEB_URL="https://github.com/LizardByte/Sunshine/releases/download/v2026.516.143833/sunshine-ubuntu-24.04-amd64.deb"

log "1/3 · Tailscale (rede privada VM <-> PC; sem abrir portas)"
if ! have tailscale; then curl -fsSL https://tailscale.com/install.sh | sh; fi
sudo tailscale up            # abre um link para você autenticar no navegador
echo "IP Tailscale desta VM (use no Moonlight):"; tailscale ip -4 || true

log "2/3 · Sunshine (host de streaming com NVENC)"
if ! have sunshine; then
  wget -qO /tmp/sunshine.deb "${SUN_DEB_URL}"
  sudo apt-get update && sudo apt-get install -y /tmp/sunshine.deb && rm -f /tmp/sunshine.deb
fi
# evita o serviço automático tentar capturar :0 (inexistente num host headless)
systemctl --user disable --now sunshine 2>/dev/null || true

log "3/3 · Iniciar Sunshine capturando o display ${DISP}"
pgrep -x sunshine >/dev/null || { nohup env DISPLAY="${DISP}" sunshine >/tmp/sunshine.log 2>&1 & sleep 3; }

TS_IP="$(tailscale ip -4 2>/dev/null | head -1)"
cat <<EOF

Sunshine no ar (captura ${DISP}). Pareie o Moonlight:
  1) No PC, abra no navegador:   https://${TS_IP:-<IP_Tailscale>}:47990
     (1ª vez: crie um usuário/senha — é o login do Sunshine)
  2) No Moonlight (PC): Add Host = ${TS_IP:-<IP_Tailscale_da_VM>}
  3) O Moonlight exibe um PIN → cole em Sunshine (Web UI, aba PIN) para parear
  4) No Moonlight, abra o app "Desktop" → aparece o :99 com o rviz, FLUIDO (NVENC)

Pré-requisitos: o Tailscale também instalado/logado no seu PC (mesma conta), e o
rviz rodando no ${DISP} (make desktop + make rviz). Logs: /tmp/sunshine.log
EOF
