#!/usr/bin/env bash
# Sobe o Autoware + a interface CARLA num único launch (e2e_simulator, simulator_type:=carla).
# Instala o wheel do CARLA no container e lança contra o mapa do Town01.
# Pré-requisitos:
#   • CARLA já rodando   → bash scripts/run_carla.sh   (outro terminal)
#   • mapa baixado       → bash setup/05_map.sh
# Headless por padrão (rviz off). Com display (NICE DCV) use: RVIZ=true bash scripts/run_autoware.sh
# Uso:  bash scripts/run_autoware.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../setup" && pwd)/lib.sh"

have docker || die "docker não encontrado."
[[ -s "${AUTOWARE_DATA}/maps/${CARLA_MAP}/lanelet2_map.osm" ]] \
  || die "Mapa ${CARLA_MAP} não encontrado em ${AUTOWARE_DATA}/maps/${CARLA_MAP}. Rode: bash setup/05_map.sh"

RVIZ="${RVIZ:-false}"

log "Autoware + interface CARLA (mapa ${CARLA_MAP}, rviz=${RVIZ}). CARLA precisa já estar rodando."
exec docker run --rm -it --gpus all --net=host \
  -v "${AUTOWARE_DATA}:/autoware_data" \
  "${AUTOWARE_IMAGE}" bash -lc "
    pip install --no-input '${CARLA_WHEEL_URL}' &&
    ros2 launch autoware_launch e2e_simulator.launch.xml \
      map_path:=/autoware_data/maps/${CARLA_MAP} \
      vehicle_model:=sample_vehicle \
      sensor_model:=carla_sensor_kit \
      simulator_type:=carla \
      rviz:=${RVIZ}
  "
