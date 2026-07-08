---
name: project-estrutura-diretorios
description: Layout de diretórios do projeto LUO (onde ficam dados, docs, código)
metadata:
  type: project
---

Projeto em `c:/Mestrado/LUO/`. Estrutura organizada em 2026-06-14:

- `references/` — material-fonte: `artigo_luo_2023.pdf`/`.txt`, `descricao_dataset.txt`, `description_of_dataset.docx`.
- `data/raw/ai_detection/` — 12 CSVs (4 cenários: bend/jam/straight/straight_constant_speed × {n,t,r}). Camada IA.
- `data/raw/rule_detection/` — `SOMEIPHeader_rule_someip.csv` + `SOMEIPHeader_rule_SD.csv`. Camada de regras.
- `data/processed/` — saída do pré-processamento (vazio ainda).
- `docs/` — `analise-artigo.md`, `descricao-dataset.md`, `plano-reproducao.md`.
- `src/data/load.py` — carrega CSVs, monta `message_id`, expõe constantes (SIGNAL_COLS, ID_TO_IDX, labels).
- `src/data/preprocess.py` — Fase 1 ✅: `build_ai_dataset()` faz normalização min-max por Message ID + janelamento (len=91, step=30) + split 80/20. Saída: X (n,91,6), M (n,91) índices de Message ID, y (n,). Rodar como módulo: `python -m src.data.preprocess`.
- `notebooks/01-exploracao-preprocessamento.ipynb` — demo de carga + pré-processamento (projeto deve ser reproduzível em notebook).
- `src/rules/`, `src/models/` — vazios (Fases 2 e 3: motor de regras e multi-GRU).
- `models/`, `results/` — saídas.

Detalhes não óbvios:
- Labels IA: **0=Tamper, 1=Normal, 2=Replay**.
- 4 Message IDs de evento: 0x14720011, 0x14720012, 0x27590010, 0x36120009.
- Pasta antiga `Dataset-for-SOME-IP-IDS-master/` pode ainda conter um `.docx` travado pelo Word; apagar após fechar o Word (cópia já está em references/).
- Ambiente: Windows, PowerShell + Bash. Não é repo git (ainda).

Ver [[project-ids-someip-reproducao]].
