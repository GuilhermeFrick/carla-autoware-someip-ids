#!/usr/bin/env bash
# Marco [3] do runbook (docs/SETUP-AWS-FASE0.md): valida a GPU no host e no Docker.
# Uso:  bash setup/00_verify_gpu.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

log "1/2 · GPU no host (nvidia-smi)"
have nvidia-smi || die "nvidia-smi não encontrado. Use a AMI 'Deep Learning Base OSS Nvidia Driver GPU AMI (Ubuntu 22.04)' ou rode: bash setup/01_base_deps.sh"
nvidia-smi

log "2/2 · GPU dentro do Docker"
have docker || die "docker não encontrado. Rode: bash setup/01_base_deps.sh"
if docker run --rm --gpus all nvidia/cuda:12.2.0-base-ubuntu22.04 nvidia-smi; then
  ok "Docker enxerga a GPU."
else
  die "Docker não acessou a GPU. Verifique o nvidia-container-toolkit (setup/01_base_deps.sh) e reinicie a sessão."
fi

log "Marco [3] OK. Próximo: bash setup/02_autoware.sh"
