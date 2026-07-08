# Atalhos para o setup da Fase 0. Rode no host Ubuntu (AWS).
# Detalhe de cada passo em docs/SETUP-AWS-FASE0.md.
.PHONY: help base gpu autoware carla bridge fase0 run-carla run-autoware fase0-run

help:
	@echo "Alvos:"
	@echo "  make base        # (fallback) driver+docker+toolkit em Ubuntu limpo"
	@echo "  make gpu         # [3] valida GPU no host e no Docker"
	@echo "  make autoware    # [4] instala Autoware Universe (Docker)"
	@echo "  make carla       # [5] baixa CARLA 0.9.15 + API Python"
	@echo "  make bridge      # [6] diagnóstico da ponte autoware_carla_interface"
	@echo "  make fase0       # gpu -> autoware -> carla (setup completo do piloto)"
	@echo "  make fase0-run   # sobe CARLA + Autoware em tmux"

base:        ; bash setup/01_base_deps.sh
gpu:         ; bash setup/00_verify_gpu.sh
autoware:    ; bash setup/02_autoware.sh
carla:       ; bash setup/03_carla.sh
bridge:      ; bash setup/04_bridge.sh
fase0: gpu autoware carla
	@echo "==> Setup base da Fase 0 concluído. Suba o piloto: make fase0-run"

run-carla:    ; bash scripts/run_carla.sh
run-autoware: ; bash scripts/run_autoware.sh
fase0-run:    ; bash scripts/tmux_fase0.sh
