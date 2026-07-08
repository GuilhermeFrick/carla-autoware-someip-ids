# Plano por fases — carla-autoware-someip-ids

Cada fase é um **marco publicável** e reduz risco antes da próxima. Decisões travadas: vsomeip
real · Autoware Universe · repo novo.

## Fase 0 — Piloto (CARLA dirigido pelo Autoware)
**Objetivo:** o carro anda sozinho no CARLA via Autoware — **ainda sem SOME/IP**.
- Ambiente: Ubuntu 22.04 + ROS2 Humble + Autoware Universe + CARLA 0.9.15 + `carla_ros_bridge`.
- Entregável: vídeo do ego dirigindo (perception→planning→control) num mapa; tópicos ROS2 vivos.
- **Risco alto:** estabilizar Autoware+CARLA+GPU. É o maior gargalo — resolver primeiro.

## Fase 1 — Ponte DDS⇄SOME/IP (fecha o loop sobre SOME/IP)
**Objetivo:** um subconjunto de tópicos vira SOME/IP e volta; o controle passa **pelo barramento**.
- Implementar os 3 módulos (Discovery/Bridge/Message) com **vsomeip** + **ARXML** mínimo.
- Sentido 1: 1–2 tópicos de sensor (ex.: `/sensing/...`) → SOME/IP pub-sub.
- Sentido 2: `/control/command` → RPC SOME/IP → nó CARLA aplica controle → **loop fechado**.
- Entregável: ego dirige com o comando trafegando em **SOME/IP real** (visto no Wireshark).

## Fase 2 — TAP + injeção de ataques
**Objetivo:** capturar o barramento e injetar ataques rotulados.
- **TAP** (tcpdump/scapy) espelha a Ethernet → **PCAP com ground truth**.
- Injetor: reusa YAML/`trigger_rate` do gerador; ataques on-the-wire (dos/fuzzy/replay) e via SD
  (mitm/relay/spoof).
- Entregável: dataset SOME/IP **rotulado, gerado no ambiente vivo** (não sintético puro).

## Fase 3 — Duplo medidor (a causalidade)
**Objetivo:** correlacionar ataque → detecção → consequência.
- Medidor 1: `content_ext → XGBoost` sobre o PCAP do TAP (detecção + latência).
- Medidor 2: sensores CARLA (collision/AEB/speed) registram o efeito físico.
- Cenários (estilo Piazzesi/Strategic): supressão de obstáculo, freio fantasma, GNSS spoof.
- Entregável: tabela **ataque × detectado? × consequência física** — o resultado central da tese.

## Fase 4 — Plataforma / ferramenta
**Objetivo:** empacotar como ferramenta reutilizável e reprodutível.
- CLI/YAML único de cenário (mundo + Autoware + ataque + medição), Docker Compose, docs.
- Modos: **gerar dataset**, **testar um modelo de IDS**, **rodar um cenário de ataque**.
- Entregável: repo publicável + dataset + notebook de reprodução → base para outras pesquisas.

## Riscos e mitigações
| Risco | Mitigação |
|---|---|
| Autoware+CARLA instável (Fase 0) | Resolver isoladamente antes de tudo; considerar cloud GPU. |
| vsomeip/ARXML complexo (Fase 1) | Começar com 1 serviço/1 método; expandir depois. |
| Sincronizar tempo (ataque↔detecção↔efeito) | Timestamp único (clock do CARLA em modo síncrono) em todos os medidores. |
| Viés sintético dos ataques | Jitter/variação (ponto das auditorias) já previsto no injetor. |

## Próximo passo imediato
Fase 0 — subir Ubuntu 22.04 + ROS2 Humble + Autoware + CARLA e obter o ego dirigindo. Definir
onde roda (WSL2 vs máquina dedicada vs cloud GPU) é o primeiro bloqueio a destravar.
