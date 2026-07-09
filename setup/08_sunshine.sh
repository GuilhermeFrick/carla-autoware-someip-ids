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

# Libera o IP Tailscale no CSRF do Sunshine (senão a Web UI em https://<ts-ip>:47990 dá CSRF error).
TS_IP="$(tailscale ip -4 2>/dev/null | head -1)"
CONF="${HOME}/.config/sunshine/sunshine.conf"
mkdir -p "${HOME}/.config/sunshine"
if [[ -n "${TS_IP}" ]] && ! grep -q "csrf_allowed_origins" "${CONF}" 2>/dev/null; then
  echo "csrf_allowed_origins = https://${TS_IP}:47990" >> "${CONF}"
  ok "csrf_allowed_origins liberado para https://${TS_IP}:47990"
fi
# encoder = vulkan: nesta VM o NVENC falha (cudaErrorInsufficientDriver), mas o Vulkan encoda
# em HARDWARE na A6000. Evita as tentativas falhas de nvenc no startup.
grep -q "^encoder" "${CONF}" 2>/dev/null || echo "encoder = vulkan" >> "${CONF}"
# capture = x11: com Xorg real, o Sunshine usaria KMS e capturaria o scanout do monitor FÍSICO —
# que num headless não existe → tela preta. X11 captura o framebuffer renderizado do :99.
grep -q "^capture" "${CONF}" 2>/dev/null || echo "capture = x11" >> "${CONF}"

log "3/3 · Iniciar Sunshine capturando o display ${DISP}"
pkill -x sunshine 2>/dev/null || true; sleep 1   # reinicia p/ aplicar a config
nohup env DISPLAY="${DISP}" sunshine >/tmp/sunshine.log 2>&1 & sleep 3

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
