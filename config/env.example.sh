#!/usr/bin/env bash
# Copie para config/env.sh e ajuste ao seu host. Os scripts de setup/ e scripts/
# carregam este arquivo automaticamente. config/env.sh é ignorado pelo git
# (contém caminhos/IP locais).

# ── Versões fixadas (não mudar sem motivo) ────────────────────────────────
export CARLA_VERSION="0.9.15"     # pinado: é a versão suportada pela ponte autoware_carla_interface
export ROS_DISTRO="humble"        # Autoware Universe = ROS2 Humble (Ubuntu 22.04)

# ── Caminhos no host Ubuntu (AWS) ─────────────────────────────────────────
export CARLA_ROOT="${HOME}/carla"
export AUTOWARE_ROOT="${HOME}/autoware"
export AUTOWARE_MAP="${HOME}/autoware_map"

# ── Conexão CARLA (referência) ────────────────────────────────────────────
export CARLA_HOST="localhost"
export CARLA_PORT="2000"
