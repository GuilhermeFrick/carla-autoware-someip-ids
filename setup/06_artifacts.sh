#!/usr/bin/env bash
# Marco [5c]: baixa os ARTEFATOS DE ML do Autoware (modelos de percepção: lidar_centerpoint,
# tensorrt_yolox, etc.) para ${AUTOWARE_DATA}. O e2e_simulator ABORTA sem eles — ex.:
#   [ERROR] [launch]: No such file: /root/autoware_data/lidar_centerpoint/centerpoint_tiny_ml_package.param.yaml
# Usa o playbook oficial download_artifacts (via ansible). Uso:  bash setup/06_artifacts.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

AWREPO="${AUTOWARE_REPO:-${HOME}/autoware}"

log "1/3 · Clonar autoware (só para a coleção ansible) em ${AWREPO}"
if [[ -d "${AWREPO}/.git" ]]; then
  ok "já existe"
else
  git clone --depth 1 https://github.com/autowarefoundation/autoware.git "${AWREPO}"
fi

log "2/3 · Instalar ansible + coleção do Autoware"
have ansible-playbook || { sudo apt-get update && sudo apt-get install -y ansible; }
cd "${AWREPO}"
ansible-galaxy collection install -f -r ansible-galaxy-requirements.yaml

log "3/3 · Baixar artefatos para ${AUTOWARE_DATA} (vários GB, alguns minutos)"
ansible-playbook autoware.dev_env.download_artifacts -e "data_dir=${AUTOWARE_DATA}"

echo
if [[ -f "${AUTOWARE_DATA}/lidar_centerpoint/centerpoint_tiny_ml_package.param.yaml" ]]; then
  ok "Artefatos OK (lidar_centerpoint presente). Próximo: make run-carla + make run-autoware."
else
  die "Não achei os modelos em ${AUTOWARE_DATA}. Confira o PLAY RECAP acima (failed=0?)."
fi
