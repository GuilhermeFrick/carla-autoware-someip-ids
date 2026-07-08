---
name: feedback-estilo-apresentacao
description: Como o usuário quer os slides/textos — evitar 1ª pessoa, expandir sigla, usar figuras reais
metadata:
  type: feedback
---

Preferências dadas pelo usuário ao montar a apresentação (aplicar em slides e textos técnicos).

- **Nada de 1ª pessoa do plural** ("rodamos", "fizemos", "treinamos", "reimplementamos",
  "reproduzimos"…). Usar forma **impessoal/passiva** ("os modelos foram executados", "RNN
  reimplementada e treinada do zero"). Também evitou "Nossa reprodução" → prefere **"Reprodução do
  trabalho"**.
- **Sigla só é expandida na 1ª menção** (ex.: "GRU (Gated Recurrent Unit)"), depois só a sigla.
- **Slides ricos em informação**, mas sem espaço vazio: quando sobra espaço, preencher com tabela/
  imagem relevante. Explicar termos que ficam implícitos (o que é N/suporte, contagem-vs-artigo,
  otimização Bayesiana etc.) com legenda curta.
- **Usar as figuras reais** dos `docs/figuras/` de cada repo (matriz de confusão, curvas, arquitetura)
  e imagens do artigo que o usuário fornece (ele salva o arquivo em `figuras/` com o nome combinado).
- Gosta de **tabelas HTML limpas** em vez de screenshots de tabela.
- Explicações com **analogia** funcionam (ex.: single-GRU = 1 generalista; multi-GRU = N especialistas
  + coordenador). Ele guarda a frase que gosta e pede para reusar literalmente.

**Por quê:** é um deck de defesa/seminário de mestrado — tom acadêmico impessoal, denso e verificável.
**Como aplicar:** ao editar o deck ([[reference-apresentacao-deck]]), varrer `-amos/-emos/-imos` antes
de fechar; puxar números dos relatórios reais; oferecer dividir uma obra em 2 slides (trabalho|resultados)
quando há muitas tabelas.
