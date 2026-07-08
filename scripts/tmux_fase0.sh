#!/usr/bin/env bash
# Orquestra a Fase 0 em uma sessão tmux com 2 painéis: CARLA (headless) e Autoware.
# O rviz2 abre a partir do painel do Autoware; visualize pelo NICE DCV.
# Uso:  bash scripts/tmux_fase0.sh   (Ctrl+B depois D para destacar; 'tmux attach -t fase0')
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../setup" && pwd)/lib.sh"

have tmux || die "tmux não encontrado (sudo apt-get install -y tmux)."
SESSION="fase0"

if tmux has-session -t "${SESSION}" 2>/dev/null; then
  warn "Sessão '${SESSION}' já existe — anexando."
  exec tmux attach -t "${SESSION}"
fi

tmux new-session -d -s "${SESSION}" -n main "bash ${REPO_ROOT}/scripts/run_carla.sh"
tmux split-window -h -t "${SESSION}:main" "sleep 8; bash ${REPO_ROOT}/scripts/run_autoware.sh"
tmux select-layout -t "${SESSION}:main" even-horizontal
log "Sessão tmux '${SESSION}' criada (CARLA | Autoware). Anexe com: tmux attach -t ${SESSION}"
exec tmux attach -t "${SESSION}"
