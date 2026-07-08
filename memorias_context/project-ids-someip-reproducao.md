---
name: project-ids-someip-reproducao
description: Objetivo do projeto — reproduzir o IDS multicamada SOME/IP de Luo et al. 2023
metadata:
  type: project
---

Projeto de mestrado: **reproduzir** o trabalho Luo et al., "A Multi-Layer Intrusion
Detection System for SOME/IP-Based In-Vehicle Network", Sensors 2023, 23, 4376
(doi 10.3390/s23094376).

**Objetivo atual (declarado pelo usuário em 2026-06-14):** validar a *relevância do artigo
e a solidez da metodologia* via reprodução independente — NÃO propor contribuição original
ainda. "Melhorar" aqui = chegar mais perto dos números do artigo, não superá-los. O usuário
demonstrou interesse em discutir contribuições originais DEPOIS de fechar a reprodução fiel.
Repo remoto: github.com/GuilhermeFrick/someip-multilayer-ids (CSVs via Git LFS).

Fatos-chave não óbvios:
- **Os autores NÃO publicaram o código do IDS** — só o dataset (github.com/yzyGo/Dataset-for-SOME-IP-IDS, ref [50] do artigo). A reprodução exige reimplementar tudo do zero.
- O IDS tem **2 camadas**: (1) regras no header/SD/intervalo/processo (Fuzzy, DoS, processo anormal); (2) **multi-GRU** no payload de eventos (Spoof: Tamper/Replay).
- **multi-GRU** = uma GRU empilhada (depth 2) por Message ID, saídas concatenadas → linear → softmax (3 classes). Vantagem sobre single-GRU: escala linear em parâmetros.
- Pré-processamento do payload (deserialização IEEE754→float) **já vem pronto** nos CSVs como signal1..6; falta normalizar (min-max por Message ID) e janelar (len=91, step=30).
- Metas a bater: regras 100%; multi-GRU acc 99,78%; single-GRU 97,40%.

Achados das fases concluídas:
- **Fase 1 (pré-proc IA):** ok — `build_ai_dataset()` gera X(n,91,6), M(n,91), y(n,) balanceado.
- **Fase 2+2b (regras):** o **dataset de regras NÃO tem coluna de label** → impossível medir accuracy/recall por pacote (o "100%" do artigo é interno ao gerador deles). Whitelist por **frequência** (legítimo domina ~45000× vs fuzzed ~2×). Resultados: Fuzzy 38284 vs 43867; Abnormal 26349 vs 33509 (return_code 8192 + missing-response 18084, **pareado por (client_id, session_id)** porque a ordem por timestamp é degenerada — blocos QQQ...RRR); **DoS inviável** (timestamps em ms com colisões). Detalhes em docs/resultados-fase2.md.

- **Fase 3 (multi-GRU):** PyTorch CPU instalado (torch 2.12). Modelo em src/models/multi_gru.py tem **13.698 parâmetros = idêntico ao artigo** (Tabela 11); pré-proc gera **82.641 seqs ≈ 82.625 do artigo**. Treino (src/models/train.py, Adam+CE, hiperparâm Tabela 9). Resultado 4 cenários/60 épocas: **accuracy 94,61%**, replay recall 8%→**91,5%** (reproduz a vantagem do multi-GRU). Gap p/ 99,78% = sem otimização Bayesiana própria + loss ainda caindo (0,128 em 60 ép). Modelo salvo em models/multi_gru_full.pt. Achado: blocos de replay têm 8 pacotes repetindo valores recentes (valores normais fora de ordem). Detalhes docs/resultados-fase3.md.

- **Fase 3b (multi vs single-GRU) — ACHADO CENTRAL:** o **single-GRU reproduz o artigo (97,66% ≈ 97,40% deles)** mas **SUPERA o multi-GRU (94,92% em 120 épocas, plateau em loss 0,119)**. Ou seja, a **tese-título do artigo (multi-GRU ≫ single-GRU) NÃO se reproduz** sob os hiperparâmetros da Tabela 9 — o oposto acontece. Nosso single-GRU casar com o número deles dá credibilidade à reprodução. Replay recall: single 94,77% vs multi 88,89%. Hipóteses: lr do multi (0,00896) oscila; detalhes de implementação não publicados; otimização Bayesiana não refeita. Detalhes em docs/resultados-fase3.md (Fase 3b). Modelos: models/single_gru_full.pt, multi_gru_full_120.pt.

- **Fase 3c (otimização Bayesiana, src/models/optimize.py, Optuna):** a busca redescobriu os hiperparâmetros do artigo (hscale=5, lr~0,009); β1 0,934→0,973 fez o multi-GRU saltar p/ **96,79%** (loss 0,079). Mesmo otimizado, multi-GRU (96,79%) só **EMPATA** com single-GRU (97,66%), não supera. Achado real = **alta variância/sensibilidade ao momento do Adam e seed** (94,9% ou 96,8% com mesmos hscale/lr), não superioridade do multi. Modelo: models/multi_gru_bayes.pt. Tudo commitado+pushed (commits até 001500c).

Pendências sugeridas: média ± desvio sobre múltiplas seeds (multi e single) p/ caracterizar variância; análise de desbalanceamento (ratios 40/20/1%).

Plano detalhado em c:/Mestrado/LUO/docs/plano-reproducao.md. Ver [[project-estrutura-diretorios]].
