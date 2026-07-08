---
name: project-contribuicoes-e-ferramentas
description: Contribuições próprias — IDS multiclasse content_ext, lição do split, gerador, eval_pcap, CARLA
metadata:
  type: project
---

Ferramentas de apoio construídas além das reproduções. Repos em [[reference-repositorios-mapa]].

> ⭐ **A contribuição central (IDS multiclasse XGBoost + content_ext) tem arquivo próprio:**
> [[project-contribuicao-multiclasse-contentext]]. Este arquivo cobre só as **ferramentas de apoio**.

## Gerador de tráfego — `someip-traffic-simulator`
- Derivado do Egomania (AGPL). Dirigido por **YAML** único: `python run_scenario.py scenarios/X.yaml`
  (`--dry-run` mostra o config). Saída: `<pcap>` + `<pcap>.labels.npy` (ground truth por pacote).
- `attack.trigger_rate` = prob. 1/N por mensagem (**menor = mais ataques**; 50 dispara bem, 2000 quase nunca).
- 7/7 taxonomia (dos, fuzzy, mitm, tamper, replay, hwfailure, + processo). Cenários prontos:
  normal, dos, fuzzy, zeroday_train_known, zeroday_test_novel.

## Ambiente de teste de PCAP — `eval_pcap.py` (no repo multiclass-contentext)
- Carrega PCAP gerado + labels → extrai content_ext (byte-model no normal do próprio PCAP, evita
  domain shift) → treina/testa → métricas + matriz. Notebook `06-testar-pcap-gerado.ipynb`.
- Modos: 70/30 auto-contido; `--test-pcap` (transfer); `--binary` (zero-day, detecção de tipo novo).
- Validado: fuzzing gerado → macro-F1 0,993 (tráfego gerado é coerente/aprendível).
- **Bug conhecido (resolvido):** XGBoost com `multi:softprob` → `predict()` retorna probs 2D; usar
  `predict_proba(...).argmax(1)`.

## CARLA — `carla-someip` (ver docs `RELATORIO.md`)
- Inspirado no yes-carla-can (CAN), mas SOME/IP. CARLA 0.9.15 + Tesla Model3 + 30 NPCs + LiDAR
  HDL-32E/GNSS/IMU. `ecu_bridge` publica 5 serviços (0x1001–0x1005) em multicast; HUD pygame; AEB
  (ISO 15623). Ataque: AEB spoofing (suppress/inject). **Próximo passo:** loop fechado bidirecional
  + Autoware (gateways someip↔ros2) → ataque com consequência física = contribuição central da tese.

Melhorias sugeridas (auditorias GPT/Gemini/Manus): ablação fina das 4 features; **jitter no gerador**
(anti-viés sintético); multi-seed p/ barras de erro. Normalização min-max é **nula no XGBoost**
(invariância monotônica) — só importa para os modelos sequenciais.
