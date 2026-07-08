# Arquitetura — carla-autoware-someip-ids

## Visão geral
Fecha o pipeline **carro virtual → cérebro autônomo → barramento real → ataque → detecção +
consequência**. A "superfície real" é o **SOME/IP sobre Ethernet** (onde o IDS atua e os ataques
são injetados). O elo com o Autoware é uma **ponte DDS⇄SOME/IP** (ROS2 usa DDS por baixo).

```
┌───────────────────────────────────────────────────────────────────────┐
│ 1. SIMULAÇÃO      CARLA  ──(carla_ros_bridge)──►  Autoware (ROS2/DDS)   │
│                   sensores                        perception→planning→control
└───────────┬───────────────────────────────────────────────┬───────────┘
   estado cinemático / sensores (DDS)          comando de controle (DDS)
            ▼                                                 ▲
┌───────────────────────────────────────────────────────────────────────┐
│ 2. TRANSPORTE     Ponte DDS ⇄ SOME/IP  (vsomeip)                        │
│   Discovery Manager · Bridge Manager · Message Router                  │  ◄── TAP (tcpdump) → PCAP
│   SD multicast (ARXML) · pub-sub + RPC                                 │
└───────────┬───────────────────────────────────────────────┬───────────┘
   injeta no barramento Ethernet                    tráfego espelhado
            ▲                                                 ▼
┌───────────┴──────────────┐   ┌─────────────────┐   ┌──────────────────────┐
│ 3. INJETOR DE ATAQUES    │   │ 4. MEDIDOR 1     │   │ 5. MEDIDOR 2         │
│ dos/fuzzy/mitm/relay/    │   │ DETECÇÃO         │   │ CONSEQUÊNCIA         │
│ replay · trigger YAML    │   │ content_ext →    │   │ collision · ego speed│
│ (do gerador) · Scapy/    │   │ XGBoost (IDS)    │   │ evento AEB (CARLA)   │
│ vsomeip                  │   │ ground truth p/  │   │ correlaciona ataque  │
└──────────────────────────┘   │ rótulo           │   │ → efeito físico      │
                               └─────────────────┘   └──────────────────────┘
```

## Camada 2 — a ponte (coração da plataforma)
Baseada no *Dynamic Bridge* (Electronics 2025) e no ASIRA (2024). Três módulos:

| Módulo | Função |
|---|---|
| **Discovery Manager** | Observa descoberta dos dois lados em tempo real: **SOME/IP-SD** (multicast) e a descoberta **DDS** do ROS2. Casa serviços ↔ tópicos. |
| **Bridge Manager** | Ciclo de vida das rotas (cria/derruba entidades) segundo um **arquivo de config da ponte** (mapeia tópico ROS2 ↔ serviço/método SOME/IP + ARXML). |
| **Message Router** | Converte tipo/QoS e **repassa** os dados nos dois sentidos (DDS→SOME/IP e SOME/IP→DDS). |

- **Sentido 1 (sensores):** Autoware/CARLA → DDS → ponte → **SOME/IP** (pub-sub de notificações).
- **Sentido 2 (controle):** Autoware `/control/command` → DDS → ponte → **SOME/IP** (RPC) → nó no
  CARLA aplica `VehicleControl` → **loop fechado**.
- **vsomeip** provê a pilha SOME/IP real; **ARXML** define serviços/instâncias/eventos e o SD
  (IP multicast + porta). O **SD é o ponto natural de injeção** (MITM/relay/spoof).

## Camada 3 — injeção de ataques
- Reaproveita a taxonomia + `trigger_rate` do `someip-traffic-simulator` (YAML), agora sobre o
  **barramento vivo** (não um PCAP pré-gerado).
- Duas superfícies: **on-the-wire** (Scapy, Ethernet raw — DoS/fuzzy/replay) e **via SD/serviço**
  (vsomeip — MITM/relay/spoof, o mais realista).
- Cada ataque carimba **ground truth** (janela de tempo + tipo) para rotular o PCAP capturado no TAP.

## Camadas 4 e 5 — duplo medidor (a causalidade)
- **Medidor 1 (detecção):** o PCAP do TAP passa pelo extrator `content_ext` → XGBoost multiclasse
  → detecção por pacote/janela. Métrica: recall/precisão por ataque, latência de detecção.
- **Medidor 2 (consequência):** sensores do CARLA (collision, ego speed, estado AEB) registram o
  **efeito físico**. Métrica: houve colisão? freio fantasma? desvio de rota?
- **Correlação:** alinha `ataque (t) → detecção (t+Δ) → consequência (t+Δ')` — é isso que nenhum
  trabalho isolado entrega.

## Mapa de reaproveitamento
| Novo (Camada) | De onde vem |
|---|---|
| IDS content_ext/XGBoost (4) | `someip-ids-multiclass-contentext` (`eval_pcap.py`, extrator) |
| Injetor YAML + ground truth (3) | `someip-traffic-simulator` (`run_scenario.py`, `attacks/`) |
| Sensores/HUD/attacks CARLA (1,3,5) | `carla-someip` (`sensors/`, `attacks/`, `hud.py`) |
| Ponte DDS⇄SOME/IP (2) | **novo** — vsomeip + ARXML, inspirado no Dynamic Bridge |
| Autoware Universe (1) | **novo** — stack ROS2 Humble |

## Ambiente-alvo
Ubuntu 22.04 · ROS2 Humble · Autoware Universe · CARLA 0.9.15 (+ `carla_ros_bridge`) · vsomeip
(COVESA) · Docker Compose (serviços AUTOSAR Adaptive). GPU necessária (Autoware perception + CARLA).
