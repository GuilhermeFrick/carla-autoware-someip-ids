# Briefing para nova instância (colar no início da conversa)

> Cole este texto para orientar um novo Claude. Ajuste os caminhos entre ⟨⟩ se necessário.

---

Olá. Sou mestrando em segurança de redes veiculares (**SOME/IP** / Automotive Ethernet) e vamos
continuar uma pesquisa longa. **Fale sempre em português.**

## Como se orientar (faça isto primeiro)
1. Na pasta de memórias ⟨`.../memory/`⟩ existe um **`MEMORY.md`** — é o **índice/mapa** de todo o
   contexto. **Leia-o primeiro.** Cada linha aponta para um arquivo com um fato; abra os que forem
   relevantes para a tarefa. Os arquivos se linkam entre si com `[[nome]]`.
2. Comece pelos destaques do índice: a **fase atual** (plataforma CARLA↔Autoware↔SOME/IP) e a
   **contribuição central** (IDS multiclasse XGBoost + `content_ext`).
3. Depois leia o **README do repositório da fase atual**: ⟨`c:/Mestrado/carla-autoware-someip-ids/README.md`⟩
   + `docs/ARQUITETURA.md`, `docs/PLANO.md` e `docs/notas-referencias.md`. Isso te dá o desenho
   completo e o plano por fases.

## Resumo do que já existe (detalhe nas memórias)
- **4 reproduções** dos principais IDS de SOME/IP (Kim/Luo/Alkhatib/SISSA), cada uma num repo com
  `docs/` e figuras. Achado recorrente: a contribuição-título dos papers muitas vezes não é robusta.
- **Contribuição central:** IDS **multiclasse XGBoost + content_ext** (5 classes, features **sem
  cabeçalho**). Avaliação honesta em 3 regimes (aleatório 0,99 / temporal 0,966 / zero-day 0,60);
  a lição do **vazamento no split 70/30** está documentada.
- **Ferramentas:** gerador de tráfego SOME/IP por **YAML** (ground truth por pacote), `eval_pcap.py`
  (testa PCAP no IDS), e o `carla-someip` (protótipo CAN-style anterior).
- **Deck de apresentação** em `someip-ids-apresentacao/reavaliacao-modelos.html` (15 slides).

## Fase atual (onde estamos agora)
Construir uma **plataforma de simulação**: **CARLA ⇄ Autoware (ROS2) ⇄ ponte DDS⇄SOME/IP (vsomeip)**,
com **injeção de ataques** no barramento Ethernet e **duplo medidor** — detecção (o meu IDS) +
consequência física (colisão/AEB no CARLA). Repo: ⟨`carla-autoware-someip-ids`⟩.
**Decisões já travadas:** vsomeip real · Autoware Universe completo · repo novo.
**Bloqueio imediato (Fase 0):** definir **onde rodar** o ambiente pesado (Ubuntu 22.04 + ROS2 Humble
+ Autoware + CARLA + GPU) — WSL2 vs máquina Ubuntu dedicada vs cloud GPU — e subir o ego dirigindo
pelo Autoware antes de qualquer código de ponte.

## Como trabalhamos (regras)
- **Ambiente aqui é Windows**; a plataforma roda em **Ubuntu+GPU** (que eu opero) — você **escreve**
  o código/config e itera pelos **logs que eu colo**. Não tente executar Autoware/CARLA/GPU.
- Git: sempre **HTTPS**, **`git pull --rebase` antes de `push`**, arquivos grandes via **LFS**.
- **Não redistribuir PCAPs grandes** nem texto integral de artigos (direito autoral).
- Nos **slides/textos**: nada de 1ª pessoa do plural ("rodamos/fizemos"); usar forma impessoal.
- Atualize a **memória** quando surgir algo novo e não óbvio; peça-me "salvar na memória" quando útil.

## O que eu quero agora
⟨escreva aqui a tarefa específica — ex.: "decidi rodar a Fase 0 em cloud GPU; escreva o passo a passo
do setup Ubuntu 22.04 + ROS2 Humble + Autoware + CARLA + carla_ros_bridge".⟩
