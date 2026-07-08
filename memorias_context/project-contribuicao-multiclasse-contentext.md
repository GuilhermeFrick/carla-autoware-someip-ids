---
name: project-contribuicao-multiclasse-contentext
description: CONTRIBUIÇÃO CENTRAL — IDS multiclasse XGBoost com features content_ext (estende o Kim)
metadata:
  type: project
---

⭐ **Principal contribuição original do mestrado** (não é reprodução). Repo:
`c:/Mestrado/someip-ids-multiclass-contentext` (GitHub: someip-ids-multiclass-contentext).
Estende o IDS binário do Kim para **multiclasse** com features comportamentais **sem cabeçalho**.

## O que é
- **XGBoost multiclasse** (`objective='multi:softprob'`) em **5 classes**: normal, dos, fuzzy,
  mitm_single, mitm_multi. (O Kim é binário; nós fazemos multiclasse.)
- Extração do Kim **reimplementada do zero** (Eqs. 1–8) e **validada**: 14.233.354 vs 14.233.347
  pacotes (Δ7); ataque 11,63% vs 11,68%. Rótulos multiclasse próprios (o dataset do Kim só publica o binário).
- **content_ext** = 12 features do Kim + **4 comportamentais** (`repeat_rate`, `someip_len`,
  `l4_len`, `src_payload_div`). Índices no X.npz (21 col.) = `list(range(12)) + [12,13,14,16]` = 16 features.
  **Zero features de cabeçalho** (fiel à tese do Kim: header causa overfitting/zero-day ruim).

## Resultado central
- **O gargalo era a REPRESENTAÇÃO, não o modelo:** Kim-12 puras dão macro-F1 0,78 (fuzzy 0,50,
  mitm_multi 0,57); com content_ext sobem para **macro-F1 0,99** (fuzzy 0,998, mitm_multi 0,989).
- Provado que header **overfitta o zero-day** (full 44,5% vs content_ext 59,5%) → content_ext é o "sweet spot".

## Avaliação honesta (3 regimes) — lição do split
- **Erro cometido:** split **aleatório 70/30** → *data leakage* temporal (pacotes da mesma rajada
  em treino E teste) → macro-F1 inflado **0,9936**.
- **Correção:** split **temporal por arquivo** (primeiros 70% cronológicos / últimos 30% de cada
  PCAP) → **0,9658** (honesto, in-scope). Zero-day (leave-one-attack-out) = **~0,60**.
- **Robusto a hiperparâmetros:** params do Kim (1000/lr0,05/depth6/sub0,8) → 0,9675 ≈ nossos
  → o sinal está nas **features**, não no config (notebook `03-params-kim-gpu`).
- `mitm_multi` é gargalo por **precisão** (0,74) e não recall (0,99): o MitM **relay** (service
  **0x100B**) republica payload legítimo byte-a-byte → parece normal; só o header o denuncia (por
  isso `is_relay` foi excluída). Doc: `docs/relatorio-validacao-split.md`.

## Onde está no repo
- `src/extract_ext.py` (extrator), `multiclass_content_ext.py` (experimento), `eval_pcap.py`
  (testa PCAP gerado), `data/ours_ext/X.npz`+`y_multi.npz` (LFS), `scripts/download_pcaps.py`.
- Notebooks: 00 (pipeline temporal correto), 02 (comparação de splits), 03 (params Kim GPU),
  05 (experimento split aleatório — ilustrativo), 06 (testar PCAP gerado).

Ferramentas de apoio (gerador, eval_pcap detalhado, CARLA) em [[project-contribuicoes-e-ferramentas]].
Contexto do Kim base em [[project-reproducoes-quatro-trabalhos]]. Mapa geral: [[reference-repositorios-mapa]].
