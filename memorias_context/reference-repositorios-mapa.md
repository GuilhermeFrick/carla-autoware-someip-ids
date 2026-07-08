---
name: reference-repositorios-mapa
description: MAPA de todos os repositórios/pastas do mestrado — caminho local + URL GitHub + propósito
metadata:
  type: reference
---

Mapa mestre do trabalho. Todos os repos são de `GuilhermeFrick`, remotos via **HTTPS** (não SSH),
CSVs/npz grandes via **Git LFS**. Rotina de git: sempre `git pull --rebase` antes de `push`.

## Reproduções das 4 referências
| Local | GitHub | O quê |
|---|---|---|
| `c:/Mestrado/KIM-repro` | someip-xgboost-reproduction | **Kim 2026** (base) — XGBoost binário, 12 features sem cabeçalho |
| `c:/Mestrado/LUO` | someip-multilayer-ids | **Luo 2023** — regras + multi-GRU (dataset via LFS) |
| `c:/Mestrado/Alkhatib2021-repro` | someip-ids-rnn-reproduction | **Alkhatib 2021** — RNN sequencial, 5 classes de processo |
| `c:/Mestrado/SISSA-repro` | someip-lstm-attention-reproduction | **SISSA/Liu 2024** — LSTM+atenção, 7 classes (safety+security) |

Cada repo de reprodução tem `docs/` com `analise-artigo.md`, `relatorio-experimento.md`,
`resultados*.md` e `docs/figuras/` (matriz-confusão, curva-roc, métricas). Números em
[[project-reproducoes-quatro-trabalhos]].

## Contribuições próprias / ferramentas
| Local | GitHub | O quê |
|---|---|---|
| `c:/Mestrado/someip-ids-multiclass-contentext` | someip-ids-multiclass-contentext | IDS **multiclasse XGBoost + content_ext** (5 classes), validação de split, `eval_pcap.py`, notebooks 00/02/03/05/06 |
| `c:/Mestrado/someip-traffic-simulator` | someip-traffic-simulator | **Gerador** SOME/IP (Egomania, AGPL) dirigido por **YAML** (`run_scenario.py`), ground truth por pacote, 7/7 taxonomia |
| `c:/Mestrado/carla-someip` | carla-someip | **CARLA** + bridge SOME/IP Python (5 serviços), sensores, AEB spoofing — protótipo CAN-style (anterior) |
| `c:/Mestrado/carla-autoware-someip-ids` | (sem remoto ainda) | ⭐ **FASE ATUAL** — plataforma CARLA↔Autoware↔SOME/IP (vsomeip) + injeção + IDS. Ver [[project-fase-plataforma-carla-autoware-someip]] |
| `c:/Mestrado/BridgeSomeIP` | (PDFs) | Referências: ASIRA, Dynamic Bridge, Piazzesi, Strategic Attacks |
| `c:/Mestrado/someip-ids-apresentacao` | (local) | **Apresentação** — ver [[reference-apresentacao-deck]] |

Mencionados na história do projeto (confirmar caminho ao usar): `someip-ensemble-zeroday`
(pipeline features+zero-day+two-layer), `someip-ids-benchmark` (terreno comum, Exp. A/B),
`c:/Mestrado/Estudo-Comparativo/estudo-comparativo-someip-ids.md` (estudo comparativo — §3 tem a
taxonomia de ataques), `c:/Mestrado/SDV_Research/detection` (apresentação original "Apresentação 3").

Detalhes de contribuições/ferramentas em [[project-contribuicoes-e-ferramentas]].
