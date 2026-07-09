---
name: project-fase-plataforma-carla-autoware-someip
description: FASE NOVA — plataforma CARLA↔Autoware↔SOME/IP para injeção de ataques + IDS (a partir de 2026-07-08)
metadata:
  type: project
---

⭐ **Fase atual do mestrado (declarada em 2026-07-08):** construir uma **plataforma de simulação**
CARLA ⇄ **Autoware** (ROS2) ⇄ **ponte SOME/IP** (vsomeip/AUTOSAR Adaptive) para **injetar ataques**
no barramento Ethernet e medir **detecção** (IDS content_ext/XGBoost — [[project-contribuicao-multiclasse-contentext]])
+ **consequência física** (colisão/AEB no CARLA). Objetivo: ferramenta para gerar datasets, testar
modelos e fomentar pesquisa.

**Repo novo:** `c:/Mestrado/carla-autoware-someip-ids` (docs: `README.md`, `docs/ARQUITETURA.md`,
`docs/PLANO.md`, `docs/SETUP-AWS-FASE0.md`; setup automatizado em `setup/`+`scripts/`+`Makefile`).
**Remoto (2026-07-08):** `https://github.com/GuilhermeFrick/carla-autoware-someip-ids.git` (HTTPS).
O `carla-someip` vira protótipo anterior (CAN-style, SOME/IP Python unidirecional).

**Decisões travadas (usuário):** (1) pilha SOME/IP = **vsomeip real** (não Python); (2) **Autoware
Universe completo** (não mock); (3) **repo novo**; (4) ambiente pesado roda em **instância GPU na
AWS** (decidido 2026-07-08: `g4dn.2xlarge` T4/16GB — opção econômica; `g5.2xlarge` A10G/24GB é o
upgrade se faltar VRAM). **AMI:** `Deep Learning Base AMI with Single CUDA (Ubuntu 24.04)`
`ami-04be28fe3137c609b` x86 (região só tinha 24.04; DLAMI traz driver+CUDA+Docker+toolkit+conda).
Descartados WSL2 e bare-metal. **Estratégia: tudo em Docker** — CARLA via imagem
`carlasim/carla:0.9.15` e Autoware via container (ambos `--net=host`), então a versão do host 24.04
é irrelevante. Setup automatizado em `setup/`+`scripts/`+`Makefile`+`docker-compose.yml`; runbook em
`docs/SETUP-AWS-FASE0.md`.

**Topologia (embasada em ASIRA/Dynamic Bridge):** o SOME/IP fica **no meio** do loop —
`CARLA ⇄ROS2⇄ ponte ⇄SOME/IP⇄ ponte ⇄ROS2⇄ Autoware`, NÃO "CARLA⇄Autoware⇄SOME/IP". Só um
subconjunto de tópicos atravessa o barramento (controle + sensores escolhidos). Os dois papers
validam a ponte ROS2⇄SOME/IP com o Autoware usando **veículo dummy**; a novidade é trocar o dummy
pelo **CARLA** + injeção + duplo medidor.

**Lacuna/contribuição:** não há paper único fazendo o pipeline completo. Blocos separados:
- Ponte ROS2⇄SOME/IP: **ASIRA** (Hong & Moon, MDPI Electronics 2024, 13/7/1303) e **Dynamic Bridge**
  (Electronics 2025, 14/18/3635) — 3 módulos: **Discovery Manager · Bridge Manager · Message Router**.
  Como ROS2 usa DDS, a ponte é **DDS⇄SOME/IP**; o **SD é o ponto de injeção**.
- Injeção+consequência no CARLA: **Piazzesi** (arXiv 2202.12991), **Strategic Safety-Critical Attacks**
  (arXiv 2204.06768).
- PDFs em `c:/Mestrado/BridgeSomeIP/`.

**Arquitetura (5 camadas):** simulação (CARLA↔Autoware) · transporte (ponte DDS⇄SOME/IP vsomeip,
TAP→PCAP) · injeção (YAML do gerador) · detecção (Medidor 1 = IDS) · consequência (Medidor 2 =
sensores CARLA). Loop fechado dá causalidade ataque→detecção→efeito.

**Plano (fases):** 0 CARLA dirigido pelo Autoware (sem SOME/IP) · 1 ponte DDS⇄SOME/IP (loop fechado
sobre SOME/IP) · 2 TAP + injeção rotulada · 3 duplo medidor (tabela ataque×detectado×consequência)
· 4 empacotar como plataforma.

**FASE 0 — PIPELINE VALIDADO HEADLESS (2026-07-09).** Rodou numa VM GPU **RTX A6000** (não-AWS: a cota
G da AWS travou; DigitalOcean sem estoque; TensorDock/Paperspace com fricção → usou-se uma VM Hyperstack-
like Ubuntu 22.04 "with Docker"). Descobertas-chave (tudo já no repo, `setup/` + `scripts/` + README):
- **Autoware NÃO precisa de setup-dev-env nem build:** usa-se a imagem pré-buildada
  `ghcr.io/autowarefoundation/autoware:universe-cuda`, que **já traz** `autoware_carla_interface` +
  `carla_sensor_kit`. (O `--no-nvidia` do setup-dev-env virou irrelevante.)
- **Integração = 1 launch:** `ros2 launch autoware_launch e2e_simulator.launch.xml simulator_type:=carla
  map_path:=/root/autoware_data/maps/Town01 vehicle_model:=sample_vehicle sensor_model:=carla_sensor_kit`
  (roda DENTRO do container). Sobe Autoware + a interface juntos.
- **3 dependências que travam se faltarem:** (1) **mapa Town01** (Lanelet2+PCD, Git LFS → baixar pela
  API do bitbucket, não `raw`); (2) **wheel do CARLA p/ py3.10** (`gezp/carla_ros`, `pip install` no
  container); (3) **artefatos de ML** (`ansible-playbook autoware.dev_env.download_artifacts
  -e data_dir=~/autoware_data`) — sem eles o launch aborta no `lidar_centerpoint`.
- **Mount:** `-v ~/autoware_data:/root/autoware_data` (data_path padrão = mapa + modelos no mesmo lugar).
- **Resultado:** CARLA (Town01, ego + 183 atores) → sensores (lidar `.../pointcloud_before_sync` ~5 Hz,
  câmeras, gnss, imu) → Autoware → **ego localizado** (`/localization/kinematic_state` com pose real).
- **Falta o marco 8:** display remoto p/ rviz (VNC+VirtualGL/EGL, pois NICE DCV exige AWS) → dar goal
  pose → gravar o ego dirigindo (vídeo-entregável).

Reaproveita: IDS content_ext, injetor YAML do `someip-traffic-simulator`, sensores/attacks do
`carla-someip`. Ver [[reference-repositorios-mapa]] e [[project-contribuicoes-e-ferramentas]].
