#!/usr/bin/env bash
# Copie para config/env.sh e ajuste ao seu host. Os scripts de setup/ e scripts/
# carregam este arquivo automaticamente. config/env.sh é ignorado pelo git.

# ── Versões fixadas ───────────────────────────────────────────────────────
export CARLA_VERSION="0.9.15"     # pinado: versão suportada pela ponte autoware_carla_interface

# ── CARLA (Docker, imagem oficial) ────────────────────────────────────────
export CARLA_IMAGE="carlasim/carla:${CARLA_VERSION}"
export CARLA_MAP="Town01"          # town carregado pela interface (precisa do mapa Autoware correspondente)
export CARLA_HOST="localhost"
export CARLA_PORT="2000"

# ── Autoware (Docker, imagem PRÉ-BUILDADA — não precisa clonar nem build) ──
export AUTOWARE_IMAGE="ghcr.io/autowarefoundation/autoware:universe-cuda"
export AUTOWARE_DATA="${HOME}/autoware_data"   # mapas; montado no container em /autoware_data

# Wheel do CARLA 0.9.15 p/ Python 3.10 (instalado dentro do container do Autoware).
# Fonte: gezp/carla_ros (build oficial para Ubuntu 22.04 / Humble).
export CARLA_WHEEL_URL="https://github.com/gezp/carla_ros/releases/download/carla-0.9.15-ubuntu-22.04/carla-0.9.15-cp310-cp310-linux_x86_64.whl"
