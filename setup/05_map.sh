#!/usr/bin/env bash
# Marco [5b]: baixa o mapa do Town01 no formato do Autoware (Lanelet2 + PointCloud) e
# monta a estrutura que o e2e_simulator espera. É montado no container em /autoware_data.
# Fonte oficial: CARLA Autoware Contents (mapas com eixo-y invertido).
# Uso:  bash setup/05_map.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

DEST="${AUTOWARE_DATA}/maps/${CARLA_MAP}"
BASE="https://bitbucket.org/carla-simulator/autoware-contents/raw/master/maps"

log "Baixando mapa ${CARLA_MAP} para ${DEST}"
mkdir -p "${DEST}"

wget -O "${DEST}/pointcloud_map.pcd" "${BASE}/point_cloud_maps/${CARLA_MAP}.pcd"
wget -O "${DEST}/lanelet2_map.osm"   "${BASE}/vector_maps/lanelet2/${CARLA_MAP}.osm"
printf 'projector_type: Local\n' > "${DEST}/map_projector_info.yaml"

echo
ls -la "${DEST}"
# valida que baixou de verdade (não uma página de erro)
if [[ -s "${DEST}/pointcloud_map.pcd" && -s "${DEST}/lanelet2_map.osm" ]]; then
  ok "Mapa ${CARLA_MAP} pronto. Próximo: subir CARLA (scripts/run_carla.sh) + Autoware (scripts/run_autoware.sh)."
else
  die "Arquivos de mapa vazios — confira a URL/rede (${BASE})."
fi
