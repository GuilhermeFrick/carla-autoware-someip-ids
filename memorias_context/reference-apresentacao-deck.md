---
name: reference-apresentacao-deck
description: Deck de apresentação (reavaliacao-modelos.html) — onde está, estrutura, como mexer
metadata:
  type: reference
---

Apresentação em `c:/Mestrado/someip-ids-apresentacao/`.

## Arquivos
- **`reavaliacao-modelos.html`** ⭐ — o deck ativo desta etapa (**15 slides**), HTML autossuficiente
  (CSS+JS próprios, navegação por setas). Continuação da "Apresentação 3" (vinda de
  `SDV_Research/detection/APRESENTACAO.html`).
- `apresentacao.html` — deck anterior estendido (31 slides, tem seção CARLA + `<video>`).
- `apresentacao.md` — resumo Marp (alternativa).
- `figuras/` — imagens (topologia Alkhatib, arquitetura SISSA `Model_Structure.png`, matrizes de
  confusão, `LUO-dataset_generation.png`, `LUO-IDS_MODEL.png`, split temporal etc.) + `carla_demo.mp4`
  (o vídeo do CARLA que o usuário ainda vai gravar).

## Estrutura do deck HTML (mecânica)
- Cada slide = `<div class="slide" id="sN">` com `slide-header` (title/tag/slide-num "N / TOTAL") +
  `slide-body`. Slide 1 = capa (`class="slide cover active"`, sem número).
- JS no fim: `const total = N`. Navega por `id="s"+cur`. **Ao adicionar/remover slides:** manter ids
  **contíguos 1..N**, atualizar `total`, e todos os `slide-num` "X / N".
- Classes CSS úteis: `cols` (2 colunas), `flow-box`, `callout callout-{blue,green,red,orange}`
  (callout SEM variante fica sem fundo), `t` (tabela), `term-def`+`term-label` (definições), `pill`.
- `.slide-body` tem `overflow-y:auto` → slides densos rolam, não cortam.

## Conteúdo (fluxo)
Reavaliação das 4 referências (como reproduzir cada uma) + taxonomia de ataques + avanços próprios
(content_ext multiclasse, erro→correção do split com 2 imagens, avaliação honesta) + gerador +
CARLA + repositórios. **O usuário reestruturou de 20 para 15 slides com outra ferramenta** —
respeitar essa consolidação, não re-expandir.

## Preferências de estilo do usuário
Ver [[feedback-estilo-apresentacao]]. Números reais vêm dos `docs/` de cada repo (não inventar).
Cada obra reproduzida tende a virar slide "o trabalho" + "resultados" (com figura do docs/figuras/).
