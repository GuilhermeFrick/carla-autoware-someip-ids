#!/usr/bin/env bash
# FALLBACK — só necessário se você NÃO usou a "Deep Learning Base OSS Nvidia Driver
# GPU AMI (Ubuntu 22.04)". Instala driver NVIDIA + Docker + NVIDIA Container Toolkit
# num Ubuntu 22.04 limpo. Na DLAMI tudo isso já vem pronto → pule direto para o 00.
# Uso:  bash setup/01_base_deps.sh   (depois REINICIE a sessão SSH)
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

[[ "$(. /etc/os-release; echo "$VERSION_ID")" == "22.04" ]] || warn "Este script foi pensado para Ubuntu 22.04."

log "1/3 · Driver NVIDIA"
if have nvidia-smi; then ok "driver já presente"; else
  sudo apt-get update
  sudo apt-get install -y ubuntu-drivers-common
  sudo ubuntu-drivers install
  warn "Driver instalado — pode exigir reboot."
fi

log "2/3 · Docker"
if have docker; then ok "docker já presente"; else
  curl -fsSL https://get.docker.com | sh
  sudo usermod -aG docker "$USER"
  warn "Adicionado ao grupo docker — REINICIE a sessão SSH para valer."
fi

log "3/3 · NVIDIA Container Toolkit"
if dpkg -s nvidia-container-toolkit >/dev/null 2>&1; then ok "toolkit já presente"; else
  distribution="$(. /etc/os-release; echo "$ID$VERSION_ID")"
  curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | \
    sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
  curl -s -L "https://nvidia.github.io/libnvidia-container/${distribution}/libnvidia-container.list" | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
  sudo apt-get update && sudo apt-get install -y nvidia-container-toolkit
  sudo nvidia-ctk runtime configure --runtime=docker
  sudo systemctl restart docker
fi

log "Base pronta. REINICIE a sessão SSH e rode: bash setup/00_verify_gpu.sh"
