#!/usr/bin/env bash
# Alternativa ao Xvfb (setup/07_desktop.sh): X server NVIDIA REAL no :99.
# Motivo: o Sunshine injeta mouse/teclado via uinput e o Xvfb IGNORA isso (mouse "travado").
# Um Xorg real lê a entrada (libinput) → mouse/teclado funcionam no streaming. Bônus: o rviz
# passa a renderizar direto na GPU (sem VirtualGL) e o Sunshine captura melhor.
# Uso:  bash setup/07b_xorg.sh   (substitui o make desktop; depois: make rviz + make sunshine)
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"
DISP="${VNC_DISPLAY:-:99}"
RES="${VNC_RES:-1920x1080x24}"; RES="${RES%x*}"   # tira a profundidade -> ex 1920x1080

log "1/6 · Instalar Xorg + driver de entrada libinput + WM"
sudo apt-get update
sudo apt-get install -y xserver-xorg-core xserver-xorg-input-libinput xinit fluxbox x11-xserver-utils mesa-utils

log "2/6 · Permitir Xorg headless (Xwrapper) e grupos input/video/render (Sunshine: uinput + NVENC)"
echo -e "allowed_users=anybody\nneeds_root_rights=yes" | sudo tee /etc/X11/Xwrapper.config >/dev/null
sudo usermod -aG input,video,render "$USER" || true
sudo udevadm control --reload && sudo udevadm trigger || true
warn "Você foi adicionado a input,video,render — precisa RE-LOGAR o SSH para valer (antes do make sunshine)."

log "3/6 · Gerar xorg.conf com o BusID da GPU"
BUS="$(nvidia-smi --query-gpu=pci.bus_id --format=csv,noheader | head -1)"   # ex 00000000:00:06.0
bus="$(echo "$BUS" | awk -F: '{print $2}')"; df="$(echo "$BUS" | awk -F: '{print $3}')"
dev="${df%%.*}"; fun="${df##*.}"
BUSID="PCI:$((16#$bus)):$((16#$dev)):$((16#$fun))"
sudo tee /etc/X11/xorg.conf >/dev/null <<EOF
Section "Files"
    # o driver da DLAMI põe nvidia_drv.so aqui (fora do caminho padrão do Xorg)
    ModulePath "/usr/lib/x86_64-linux-gnu/nvidia/xorg"
    ModulePath "/usr/lib/xorg/modules"
EndSection
Section "ServerLayout"
    Identifier "layout"
    Screen 0 "screen0"
EndSection
Section "Device"
    Identifier "nvidia"
    Driver "nvidia"
    BusID "${BUSID}"
    Option "AllowEmptyInitialConfiguration" "true"
EndSection
Section "Screen"
    Identifier "screen0"
    Device "nvidia"
    DefaultDepth 24
    SubSection "Display"
        Depth 24
        Virtual ${RES/x/ }
    EndSubSection
EndSection
EOF
ok "BusID=${BUSID} · Virtual ${RES}"

log "4/6 · Parar Xvfb/x11vnc/fluxbox antigos"
pkill -x x11vnc 2>/dev/null || true; pkill -x fluxbox 2>/dev/null || true; pkill -x Xvfb 2>/dev/null || true; sleep 1

log "5/6 · Subir Xorg ${DISP}"
sudo pkill -x Xorg 2>/dev/null || true; sleep 1
sudo nohup X "${DISP}" -config /etc/X11/xorg.conf -nolisten tcp vt1 >/tmp/xorg.stdout 2>&1 &
sleep 4
if ! pgrep -x Xorg >/dev/null; then
  warn "Xorg não subiu. Log real:"
  sudo tail -n 40 "/var/log/Xorg.99.log" 2>/dev/null || tail -n 40 /tmp/xorg.stdout
  die "Cole o log acima (procure 'no screens found', 'Failed to load', 'vt')."
fi

log "6/6 · Permissões + WM"
export DISPLAY="${DISP}"
xhost +local: >/dev/null 2>&1 || true
pgrep -x fluxbox >/dev/null || { nohup fluxbox >/tmp/fluxbox.log 2>&1 & sleep 1; }

echo
ok "Xorg NVIDIA no ${DISP}. Verifique a GPU:"
echo "  DISPLAY=${DISP} glxinfo | grep -i 'OpenGL renderer'   → deve ser NVIDIA RTX A6000"
cat <<EOF

Próximos:
  make rviz       # agora GPU NATIVO (o vglrun continua ok, mas nem precisa)
  make sunshine   # mouse/teclado passam a funcionar no Moonlight
Obs: se você tinha entrado no grupo 'input' agora, pode precisar reabrir a sessão SSH.
EOF
