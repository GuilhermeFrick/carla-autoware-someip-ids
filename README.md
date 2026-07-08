# carla-autoware-someip-ids

**Plataforma de simulação para segurança de SOME/IP em veículos autônomos.**
CARLA ⇄ **Autoware** (ROS2) ⇄ **ponte SOME/IP** (vsomeip, AUTOSAR Adaptive) — com **injeção de
ataques** no barramento Ethernet e **duplo medidor**: detecção (IDS `content_ext`/XGBoost) e
consequência física (colisão/AEB no CARLA).

## Por que existe (a lacuna)
Não há, na literatura, um pipeline único **CARLA → Autoware → AUTOSAR Adaptive → injeção no
SOME/IP → detecção + consequência**. Os blocos existem separados:
- **Ponte ROS2⇄SOME/IP**: ASIRA (Hong & Moon, 2024) e o *Dynamic Bridge* (2025) — 3 módulos.
- **Injeção + consequência no CARLA**: Piazzesi et al. (2022), *Strategic Safety-Critical Attacks* (2022).

**A contribuição é a plataforma que fecha o pipeline** — uma ferramenta para (1) gerar datasets
rotulados, (2) testar modelos de IDS, e (3) fomentar pesquisa na área.

## Arquitetura (5 camadas)
```
1. SIMULAÇÃO     CARLA ⇄ Autoware (ROS2): perception → planning → control
2. TRANSPORTE    Ponte DDS⇄SOME/IP (vsomeip · SD multicast · pub-sub/RPC)      ◄─ TAP (tcpdump) → PCAP
3. INJEÇÃO       DoS / fuzzy / mitm(relay) / replay · trigger por YAML · Scapy/vsomeip
4. DETECÇÃO      content_ext → XGBoost multiclasse (Medidor 1)
5. CONSEQUÊNCIA  collision sensor · ego speed · evento AEB no CARLA (Medidor 2)
```
O **loop é fechado** (o controle volta ao CARLA) → o ataque produz **efeito físico verificável**.

## Decisões desta fase
- **Pilha SOME/IP:** vsomeip real (COVESA) — fidelidade AUTOSAR Adaptive.
- **Autoware:** Autoware Universe completo (perception→planning→control).
- **Repo:** este, novo (o `carla-someip` fica como protótipo CAN-style anterior).

## Reaproveitado dos repos existentes
- **IDS** `content_ext → XGBoost` (de `someip-ids-multiclass-contentext`) — Medidor 1.
- **Injetor por YAML + ground truth** (de `someip-traffic-simulator`).
- **Sensores / attacks / HUD** (de `carla-someip`).

## Documentos
- [`docs/ARQUITETURA.md`](docs/ARQUITETURA.md) — desenho detalhado (ponte de 3 módulos, pontos de injeção, medidores).
- [`docs/PLANO.md`](docs/PLANO.md) — plano por fases (0 a 4), marcos, dependências e riscos.
- [`docs/SETUP-AWS-FASE0.md`](docs/SETUP-AWS-FASE0.md) — variante específica para AWS (opcional; o guia oficial é o abaixo).

---

# Setup do ambiente (Fase 0) — siga na ordem

Tudo roda **em Docker**. O host só precisa de **driver NVIDIA + Docker + NVIDIA Container Toolkit**;
a versão do Ubuntu do host é indiferente (22.04 ou 24.04). Legenda: **✓ validado** · **⏳ em iteração**.

## 0. Provisionar a VM GPU
Qualquer provedor que dê uma **VM de verdade** (não container — RunPod/Vast não servem, pois exigem
Docker-in-Docker). Já testado: TensorDock / Hyperstack / DigitalOcean.
- **GPU:** ≥ 16 GB VRAM (ideal 24 GB+ — ex.: RTX A6000, A5000, RTX 4090, L40).
- **Imagem:** de preferência **"Ubuntu 22.04 … with Docker"** (já traz driver + Docker + toolkit).
  Se for Ubuntu puro, o passo 2 instala o que faltar.
- **Disco:** ≥ 250 GB (imagem do CARLA ~10 GB + imagens do Autoware, dezenas de GB).
- **SSH:** cadastre sua chave pública; conecte por chave (sem senha).

## 1. Conectar e clonar
```bash
ssh -i ~/.ssh/SUA_CHAVE ubuntu@IP_DA_VM        # usuário pode ser 'ubuntu' ou 'root'
git clone https://github.com/GuilhermeFrick/carla-autoware-someip-ids.git
cd carla-autoware-someip-ids
cp config/env.example.sh config/env.sh
```

## 2. Validar a GPU — marco [3] ✓
```bash
make gpu        # nvidia-smi no host E dentro do Docker
# Se reclamar do nvidia-container-toolkit (Ubuntu puro), rode antes:  make base
```
**OK quando:** aparece a GPU nas duas verificações (host e container).

## 3. CARLA em Docker — marco [5] ✓
```bash
make carla      # baixa carlasim/carla:0.9.15 (~10 GB) + smoke test headless
```
**OK quando:** o log mostra o banner do Unreal (`4.26.x ... Release-4.26`) **sem erro de Vulkan**
(o aviso `xdg-user-dir: not found` é inofensivo).

## 4. Instalar o Autoware (Docker) — marco [4]
```bash
make autoware   # = ./setup-dev-env.sh -y docker --no-nvidia (NÃO instala CUDA no host)
```
> O `--no-nvidia` é essencial: sem ele, o Autoware tenta instalar `nvidia-open` e **conflita com o
> driver já presente na VM** (`libnvidia-gl-... : Conflicts: libnvidia-gl`). A CUDA vem dentro do
> container do Autoware.

**OK quando:** o `PLAY RECAP` termina com **`failed=0`**.

## 5. Subir o container do Autoware e achar a interface CARLA — ⏳
```bash
make run-autoware      # baixa a imagem do Autoware (grande) e entra no container
# DENTRO do container:
ros2 pkg list | grep -i carla
```
> A VM é **headless**: se o `run-autoware` falhar por X11/DISPLAY, cole o erro — ajustamos para o
> modo sem interface (a visualização do rviz2 vem depois, via NICE DCV ou port-forward de SSH).
> O resultado do `ros2 pkg list | grep -i carla` diz se a ponte `autoware_carla_interface` já vem na
> imagem ou se precisamos adicioná-la.

## 6. Ponte CARLA ⇄ Autoware — ⏳
```bash
make bridge     # diagnóstico (rode do host; a checagem real é DENTRO do container, passo 5)
```
Depende do resultado do passo 5. Aqui entra o `ros2 launch` da interface + o `pip install carla==0.9.15`
dentro do container. **A definir por log.**

## Objetivo da Fase 0
Ego **dirigindo sozinho** no CARLA via Autoware (perception → planning → control), **ainda sem
SOME/IP**. A ponte SOME/IP real é a Fase 1.

## Pausar a VM (custo)
Pare a VM quando não estiver usando. Em AWS/Azure/GCP/TensorDock/Hyperstack: **stop/deallocate** para
de cobrar o compute (paga só o disco). No **DigitalOcean**, desligado **continua cobrando** → snapshot
+ destroy.

## Status
**Fase 0 em andamento.** Validados: GPU no Docker (marco 3) e CARLA headless (marco 5). Em iteração:
subir o container do Autoware (marco 4/5) e a ponte (marco 6).
