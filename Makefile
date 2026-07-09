# Atalhos para o setup da Fase 0 (tudo em Docker). Rode no host da VM GPU.
# Detalhe de cada passo no README (seção "Setup do ambiente").
.PHONY: help base gpu carla autoware map artifacts desktop sunshine run-carla run-autoware rviz fase0 fase0-run

help:
	@echo "Ordem da Fase 0:"
	@echo "  make gpu          # [3]  valida GPU no host e no Docker"
	@echo "  make carla        # [5a] baixa imagem do CARLA 0.9.15 + smoke test"
	@echo "  make autoware     # [4]  baixa a imagem pré-buildada do Autoware (universe-cuda)"
	@echo "  make map          # [5b] baixa o mapa do Town01 (Lanelet2 + PointCloud)"
	@echo "  make artifacts    # [5c] baixa os modelos de ML do Autoware (obrigatório!)"
	@echo "  ---- rodar o piloto ----"
	@echo "  make run-carla    # sobe o CARLA (terminal 1)"
	@echo "  make run-autoware # sobe Autoware + interface CARLA (terminal 2)"
	@echo "  make fase0-run    # os dois acima em tmux"
	@echo "  ---- parte gráfica (ver/dirigir no rviz) ----"
	@echo "  make desktop      # [8a] desktop virtual + VNC (localhost:5900 via túnel SSH)"
	@echo "  make rviz         # [8b] rviz na GPU (VirtualGL/EGL) — use se o software GL estiver lento"
	@echo "                    #      (Autoware headless: make run-autoware SEM RVIZ)"
	@echo "  make sunshine     # [8c] streaming NVENC (Sunshine+Moonlight+Tailscale) — muito mais fluido que VNC"
	@echo "  base:  make base  # (fallback) driver+docker+toolkit em host sem eles"

base:         ; bash setup/01_base_deps.sh
gpu:          ; bash setup/00_verify_gpu.sh
carla:        ; bash setup/03_carla.sh
autoware:     ; bash setup/02_autoware.sh
map:          ; bash setup/05_map.sh
artifacts:    ; bash setup/06_artifacts.sh
desktop:      ; bash setup/07_desktop.sh
sunshine:     ; bash setup/08_sunshine.sh

run-carla:    ; bash scripts/run_carla.sh
run-autoware: ; bash scripts/run_autoware.sh
rviz:         ; bash scripts/run_rviz.sh
fase0-run:    ; bash scripts/tmux_fase0.sh

fase0: gpu carla autoware map artifacts
	@echo "==> Setup da Fase 0 pronto. Suba o piloto: make fase0-run (ou run-carla + run-autoware)"
