# Notas de referência — decisões de implementação a partir dos 4 artigos

Textos em [`references/`](../references/). Aqui: **o que cada paper dá de concreto** para construir
a plataforma (não resumo acadêmico — decisões de engenharia).

---

## 1. ASIRA (2024) — a ponte ROS2⇄SOME/IP (espinha dorsal)
`references/asira-ros2-adaptive-autosar.txt`

**Como a ponte funciona (fluxo exato do paper):**
- A ponte tem um **SD Server** (SOME/IP Service Discovery) + um **RPC Publish/Subscribe Server**.
- **Dois nós de ponte:**
  - **Kinematic State Subscriber** — recebe odometria do veículo via **RPC SOME/IP** → publica em tópico ROS2 (sentido sensor).
  - **Control Command Publisher** — assina o tópico ROS2 `/control/command` → converte em payload RPC → envia via **RPC SOME/IP** (sentido controle).
- **Sequência de descoberta:**
  1. SD Server abre servidor com **IP multicast + porta lidos do ARXML** + endpoints dos RPC Servers.
  2. Nós de ponte entram no grupo multicast e enviam **`findService`**.
  3. SD Server confere o **Service ID** → devolve o **endpoint RPC** correspondente.
  4. Nós conectam ao RPC Server e trocam dados; conversão **tópico ROS2 ↔ byte array (payload RPC)**.

**➡️ Para nós:**
- Replicar exatamente esses **2 nós** (Kinematic State ↔ odometria; Control Command ↔ controle) fecha o loop.
- O **ARXML** define serviços/IDs + o multicast/porta do SD. É onde configuramos o barramento.
- **Ponto de injeção nº 1 = o SD:** um atacante que responde `findService` ou emite `OfferService`
  forjado redireciona o endpoint → **MITM/relay** (o mesmo padrão do nosso `mitm_multi`/0x100B).

---

## 2. Dynamic Bridge (2025) — refinamento (SD dinâmico + QoS)
`references/dynamic-bridge-2025.txt`

**3 módulos (evolução do ASIRA estático):**
- **Discovery Manager** — detecta eventos de descoberta dos **dois domínios em tempo real**
  (SOME/IP-SD **e** a descoberta DDS do ROS2); casa serviço ↔ tópico dinamicamente.
- **Bridge Manager** — ciclo de vida das rotas (cria/derruba entidades conforme uso) segundo um
  **arquivo de configuração da ponte**.
- **Message Router** — **converte QoS** e repassa nos dois sentidos.

**Problema que ele resolve (e que teremos):** criação estática desperdiça recursos; e há
**incompatibilidade de QoS** — DDS tem QoS ricas (reliability, durability, deadline) que o
SOME/IP não expõe igual. Publisher/Subscriber precisam de QoS compatível ou há perda de dados.

**➡️ Para nós:**
- Começar **estático** (ASIRA) na Fase 1; adotar os **3 módulos + arquivo de config** quando
  escalar (Fase 4). O `bridge config file` mapeia `tópico ROS2 ↔ serviço/método SOME/IP + ARXML`.
- **Mapeamento de QoS DDS↔SOME/IP** é um risco real (registrar no PLANO). Manter QoS simples
  (reliable/volatile) no começo.

---

## 3. Piazzesi (2022) — metodologia de injeção
`references/piazzesi-attacks-faults-carla.txt`

Campanha experimental injetando **ataques adversariais + falhas de software** num **agente**
treinado de direção no CARLA. Mostra que perturbações pequenas (falhas HW/SW) enganam o ML →
decisões erradas → ameaça de segurança. Abordagem **reprodutível, só ferramentas open-source**.

**➡️ Para nós:**
- Modelo de **campanha sistemática e reprodutível** de injeção (varrer ataques × cenários).
- Diferença-chave: eles injetam **no agente**; nós injetamos **na rede (SOME/IP)** — mais realista
  para IDS de rede. A metodologia de campanha + medir impacto de segurança transfere.

---

## 4. Strategic Safety-Critical Attacks (2022) — consequência + timing
`references/strategic-safety-critical-attacks-adas.txt`

HiL: **OpenPilot + CARLA + simulador de reação do motorista + motor de fault injection**. Investiga
resiliência do ADAS a ataques que miram o **sistema de controle em momentos oportunos**.
**Achado central: ataques "Context-Aware" atingem 83,4% de sucesso** — **o timing importa** (atacar
no momento certo do cenário).

**➡️ Para nós (Medidor 2 e o injetor):**
- **Não disparar ataque aleatoriamente** — disparar **context-aware** (ex.: `AEB suppress` só quando
  há obstáculo real à frente; `phantom brake` só com via livre). Muito mais impactante e realista.
- **Métricas de consequência:** taxa de sucesso do ataque, hazard/colisão, e a "janela de
  intervenção". Isso define o **Medidor 2** (collision sensor + estado AEB + ego speed no CARLA).

---

## Decisões consolidadas para a plataforma
1. **Ponte (Fase 1):** implementar os 2 nós do ASIRA (Kinematic State ↔ Control Command) com
   **vsomeip + ARXML**; SD com multicast lido do ARXML. Estático primeiro; 3 módulos depois.
2. **Injeção (Fase 2):** 2 superfícies — **SD/serviço** (MITM/relay/spoof, via vsomeip) e
   **on-the-wire** (DoS/fuzzy/replay, Scapy). Trigger **context-aware** (lição do Strategic), com
   ground truth por janela (reusa YAML do gerador).
3. **Medição (Fase 3):** Medidor 1 = IDS content_ext sobre PCAP do TAP; Medidor 2 = colisão/AEB/
   velocidade do CARLA. Correlação por **timestamp único** (CARLA em modo síncrono).
4. **QoS DDS↔SOME/IP:** manter simples no início; tratar como risco (Dynamic Bridge).
