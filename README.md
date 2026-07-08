# carla-autoware-someip-ids

**Plataforma de simulação para segurança de SOME/IP em veículos autônomos.**
CARLA ⇄ **Autoware** (ROS2) ⇄ **ponte SOME/IP** (vsomeip, AUTOSAR Adaptive) — com **injeção de
ataques** no barramento Ethernet e **duplo medidor**: detecção (IDS `content_ext`/XGBoost) e
consequência física (colisão/AEB no CARLA).

## Por que existe (a lacuna)
Não há, na literatura, um pipeline único **CARLA → Autoware → AUTOSAR Adaptive → injeção no
SOME/IP → detecção + consequência**. Os blocos existem separados:
- **Ponte ROS2⇄SOME/IP**: ASIRA (Hong & Moon, 2024) e o *Dynamic Bridge* (2025) — 3 módulos.
- **Injeção + consequência no CARLA**: Piazzesi et al. (2022), *Strategic Safety-Critical Attacks* (2022).

**A contribuição é a plataforma que fecha o pipeline** — uma ferramenta para (1) gerar datasets
rotulados, (2) testar modelos de IDS, e (3) fomentar pesquisa na área.

## Arquitetura (5 camadas)
```
1. SIMULAÇÃO     CARLA ⇄ Autoware (ROS2): perception → planning → control
2. TRANSPORTE    Ponte DDS⇄SOME/IP (vsomeip · SD multicast · pub-sub/RPC)      ◄─ TAP (tcpdump) → PCAP
3. INJEÇÃO       DoS / fuzzy / mitm(relay) / replay · trigger por YAML · Scapy/vsomeip
4. DETECÇÃO      content_ext → XGBoost multiclasse (Medidor 1)
5. CONSEQUÊNCIA  collision sensor · ego speed · evento AEB no CARLA (Medidor 2)
```
O **loop é fechado** (o controle volta ao CARLA) → o ataque produz **efeito físico verificável**.

## Decisões desta fase
- **Pilha SOME/IP:** vsomeip real (COVESA) — fidelidade AUTOSAR Adaptive.
- **Autoware:** Autoware Universe completo (perception→planning→control).
- **Repo:** este, novo (o `carla-someip` fica como protótipo CAN-style anterior).

## Reaproveitado dos repos existentes
- **IDS** `content_ext → XGBoost` (de `someip-ids-multiclass-contentext`) — Medidor 1.
- **Injetor por YAML + ground truth** (de `someip-traffic-simulator`).
- **Sensores / attacks / HUD** (de `carla-someip`).

## Documentos
- [`docs/ARQUITETURA.md`](docs/ARQUITETURA.md) — desenho detalhado (ponte de 3 módulos, pontos de injeção, medidores).
- [`docs/PLANO.md`](docs/PLANO.md) — plano por fases (0 a 4), marcos, dependências e riscos.
- [`docs/SETUP-AWS-FASE0.md`](docs/SETUP-AWS-FASE0.md) — runbook do ambiente (AWS GPU · Ubuntu 22.04 · ROS2 Humble · Autoware · CARLA).

## Setup do ambiente (Fase 0)
Ambiente-alvo: **instância GPU na AWS** (`g5.2xlarge`) com a AMI *Deep Learning Base OSS Nvidia
Driver GPU (Ubuntu 22.04)*. Os scripts em [`setup/`](setup/) automatizam o runbook — clone o repo
na instância e rode marco a marco:

```bash
cp config/env.example.sh config/env.sh   # ajuste caminhos se quiser
make gpu        # [3] valida GPU (host + Docker)
make autoware   # [4] Autoware Universe via Docker
make carla      # [5] baixa a imagem Docker do CARLA 0.9.15 + smoke test
make bridge     # [6] diagnóstico da ponte autoware_carla_interface
make fase0-run  # sobe CARLA + Autoware (tmux) → ego dirigindo
```

Cada marco tem um ponto de parada para colar log (o ambiente roda no Ubuntu; o código é escrito no
Windows). Detalhes e solução de problemas em [`docs/SETUP-AWS-FASE0.md`](docs/SETUP-AWS-FASE0.md).

## Status
Fase de **implementação — Fase 0** (subir o ambiente na AWS: ego dirigindo pelo Autoware, sem SOME/IP).
