---
name: project-reproducoes-quatro-trabalhos
description: As 4 reproduções (Kim/Luo/Alkhatib/SISSA) — números e achado central de cada uma
metadata:
  type: project
---

Reproduzimos os 4 principais IDS de SOME/IP (Colab T4). Repos em [[reference-repositorios-mapa]].
Progressão: Alkhatib (RNN, comm-anomalies) → Luo (regras+GRU) → SISSA (DL+atenção, safety+security);
Kim é a linha paralela (XGBoost, features sem cabeçalho) e nossa **base**.

## Kim 2026 · XGBoost (base) — `someip-xgboost-reproduction`
Binário, 12 features comportamentais SEM cabeçalho, ~14,2M pacotes (~12% ataque), vSomeIP 9 ECUs.
Reprodução: ROC-AUC **0,987** (0,99), PR-AUC 0,928 (0,93), F1 pond. 0,966 (0,97).
**Achado:** o "F1 0,97" é PONDERADO (dominado pelo normal ~88%); o **F1 da classe ataque é 0,84,
recall 0,73 → ~27% dos ataques passam** (222.751 FN). Bom como filtro de 1ª linha, não IDS autônomo.

## Luo 2023 · regras + multi-GRU — `someip-multilayer-ids`
2 camadas: regras (Fuzzy/DoS/processo) + multi-GRU (payload → Normal/Tamper/Replay). Dataset por
Prescan→Simulink→CANoe (payload semântico ADAS). **multi-GRU = 4 GRUs** (uma por Message ID de
evento: 0x14720011/12, 0x27590010, 0x36120009), 13.698 params.
**Achado central 🔴:** a tese do artigo (multi-GRU > single-GRU, 99,78% vs 97,40%) **NÃO se
reproduz**. O single-GRU (97,66% ≈ artigo) SUPERA o multi-GRU (94,92%); mesmo com otimização
Bayesiana própria o multi só chega a 96,79% (empata). História real = alta sensibilidade a
hiperparâmetros/seed. Detalhes em [[project-ids-someip-reproducao]].

## Alkhatib 2021 · RNN — `someip-ids-rnn-reproduction`
Testbed: 8 servidores + 8 clientes + atacante MITM. 5 classes de processo (Normal, Error-on-Event,
Error-on-Error, Missing Response, Missing Request). Amostra = 60 pacotes × 195 (one-hot do
cabeçalho); RNN Entrada(195)→SimpleRNN(50)→Densa(10)→Softmax(5). Repo oficial publica dados + 3
RNNs treinados, **sem código**.
**Achado:** os 3 modelos publicados reproduzem a Tabela VII por inferência (98,05/97,91/**98,02%**;
o da tabela por-classe é o **rnn…204132**). Treino do zero (PyTorch) ~97% (gradient clipping
essencial). Error-on-Error é o gargalo (F1 0,73–0,86; minoritária, N=54).

## SISSA/Liu 2024 · LSTM+atenção — `someip-lstm-attention-reproduction`
**7 classes**, unifica safety (Failure/Weibull, inédito) + security (DDoS, FI, FS, ReqNoRes,
ResNoReq). Janela 128×25; PMB (Packet Mapping Block, afim aprendível) + backbones CNN/RNN/LSTM
com/sem RSAB (Residual Self-Attention). Publica código + dados.
**Achado:** SISSA-L-A **99,39%** (artigo 99,7%) — a melhor reprodução. **Janela 128 é decisiva**
(64→128 = 94,1%→99,4%). ⚠️ A autoatenção RSAB **quase não ajuda** (LSTM puro empata). Ressalva:
dataset **balanceado** (515/classe) é irrealista.

**Padrão comum dos achados:** os 4 reproduzem as métricas globais, mas a **contribuição-título**
frequentemente não é robusta (multi-GRU do Luo, RSAB do SISSA) e as **métricas globais mascaram a
classe de ataque** (recall do Kim). Lição: reportar por-classe/recall, não só F1 ponderado.
