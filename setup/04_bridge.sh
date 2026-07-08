#!/usr/bin/env bash
# Marco [6] do runbook: ponte CARLA↔Autoware (autoware_carla_interface).
# ATENÇÃO: passo de MAIOR INCERTEZA (ver docs/SETUP-AWS-FASE0.md §6). Nome de pacote,
# launch e deps Python variam com a tag do Autoware clonada. Este script NÃO chuta
# comandos — ele COLETA o diagnóstico para escrevermos o launch/params certos.
# Uso:  bash setup/04_bridge.sh   (e cole a saída aqui)
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

[[ -d "${AUTOWARE_ROOT}" ]] || die "Autoware não encontrado em ${AUTOWARE_ROOT}. Rode setup/02_autoware.sh"

log "Diagnóstico da interface CARLA no Autoware clonado"
echo "── Conteúdo de simulator/ (procuramos carla_autoware / autoware_carla_interface):"
ls -1 "${AUTOWARE_ROOT}/simulator" 2>/dev/null || echo "  (pasta simulator/ não existe nesta tag)"

echo
echo "── Ocorrências de 'carla' na árvore do Autoware (nomes de pacote):"
grep -ril --include=package.xml carla "${AUTOWARE_ROOT}" 2>/dev/null | head -n 20 || echo "  (nenhum package.xml com 'carla')"

cat <<EOF

DENTRO do container Autoware (bash scripts/run_autoware.sh), rode e cole:
  ros2 pkg list | grep -i carla
  ls src/simulator 2>/dev/null || true
A partir dessa saída eu escrevo o ros2 launch + params exatos da ponte.
EOF
