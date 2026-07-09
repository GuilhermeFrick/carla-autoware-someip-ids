#!/usr/bin/env bash
# Sobe o Autoware + a interface CARLA num único launch (e2e_simulator, simulator_type:=carla).
# Instala o wheel do CARLA no container e lança contra o mapa do Town01.
# Pré-requisitos:
#   • CARLA já rodando   → bash scripts/run_carla.sh   (outro terminal)
#   • mapa baixado       → bash setup/05_map.sh
#   • artefatos de ML    → bash setup/06_artifacts.sh  (senão o launch aborta)
# Variáveis:
#   RVIZ=true    → abre o rviz (precisa de display/NICE DCV). Padrão: false (headless).
#   LIGHT=true   → sensor mapping leve (1 câmera em vez de 6). Bom para reduzir carga/instabilidade.
# Uso:  bash scripts/run_autoware.sh
#   (para salvar log:  bash scripts/run_autoware.sh 2>&1 | tee ~/aw.log)
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../setup" && pwd)/lib.sh"

have docker || die "docker não encontrado."
[[ -s "${AUTOWARE_DATA}/maps/${CARLA_MAP}/lanelet2_map.osm" ]] \
  || die "Mapa ${CARLA_MAP} não encontrado em ${AUTOWARE_DATA}/maps/${CARLA_MAP}. Rode: bash setup/05_map.sh"

RVIZ="${RVIZ:-false}"
LIGHT="${LIGHT:-false}"
TTY=""; [ -t 1 ] && TTY="-t"   # -t só quando há terminal (permite piping para tee)

log "Autoware + interface CARLA (mapa ${CARLA_MAP}, rviz=${RVIZ}, light=${LIGHT}). CARLA precisa já estar rodando."
# Monta em /root/autoware_data = data_path padrão do Autoware (onde ele procura mapa E modelos de ML).
exec docker run --rm -i ${TTY} --gpus all --net=host \
  -v "${AUTOWARE_DATA}:/root/autoware_data" \
  "${AUTOWARE_IMAGE}" bash -lc "
    pip install --no-input '${CARLA_WHEEL_URL}' &&
    ros2 launch autoware_launch e2e_simulator.launch.xml \
      map_path:=/root/autoware_data/maps/${CARLA_MAP} \
      vehicle_model:=sample_vehicle \
      sensor_model:=carla_sensor_kit \
      simulator_type:=carla \
      rviz:=${RVIZ} \
      use_light_weight_sensor_mapping:=${LIGHT}
  "
