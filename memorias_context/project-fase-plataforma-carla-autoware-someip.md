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
AWS** (decidido 2026-07-08: `g5.2xlarge`, AMI *Deep Learning Base OSS Nvidia Driver GPU Ubuntu 22.04*)
— descartados WSL2 e bare-metal. Runbook em `docs/SETUP-AWS-FASE0.md`.

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
· 4 empacotar como plataforma. **Fase 0 em andamento (2026-07-08):** provisionar a instância AWS e
subir o ego dirigindo. Passo de maior incerteza = ponte `autoware_carla_interface` (nome/launch
variam com a tag do Autoware; `setup/04_bridge.sh` coleta diagnóstico p/ iterar por log).

Reaproveita: IDS content_ext, injetor YAML do `someip-traffic-simulator`, sensores/attacks do
`carla-someip`. Ver [[reference-repositorios-mapa]] e [[project-contribuicoes-e-ferramentas]].
