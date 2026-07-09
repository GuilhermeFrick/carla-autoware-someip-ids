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

## 4. Baixar a imagem do Autoware (Docker) — marco [4] ✓
```bash
make autoware   # docker pull ghcr.io/autowarefoundation/autoware:universe-cuda (imagem grande)
```
Usa a **imagem pré-buildada** — **não** precisa clonar o Autoware nem rodar `setup-dev-env`. Ela já
traz `autoware_carla_interface` + `carla_sensor_kit`.
**OK quando:** o script lista os pacotes carla no fim.

## 5. Baixar o mapa do Town01 — marco [5b] ✓
```bash
make map        # Lanelet2 + PointCloud do Town01 → ~/autoware_data/maps/Town01
```
**OK quando:** `pointcloud_map.pcd` (~190 MB) e `lanelet2_map.osm` baixam com tamanho > 0.
Os `.pcd` são Git LFS → o script baixa pela API do bitbucket (o endpoint `raw` dá 404).

## 6. Baixar os artefatos de ML do Autoware — marco [5c] ✓ (OBRIGATÓRIO)
```bash
make artifacts  # clona autoware (p/ ansible) + download_artifacts → ~/autoware_data
```
Baixa os modelos de percepção (lidar_centerpoint, tensorrt_yolox, etc.). **Sem eles o launch aborta**
com `No such file: .../lidar_centerpoint/centerpoint_tiny_ml_package.param.yaml`. São vários GB.
**OK quando:** `~/autoware_data/lidar_centerpoint/` existe (com o `.param.yaml`).

## 7. Rodar o piloto (CARLA + Autoware + interface) — marco [7] ✓ (pipeline validado headless)
Um único launch (`e2e_simulator.launch.xml simulator_type:=carla`) sobe o Autoware **e** a interface
CARLA. Dois terminais:
```bash
# terminal 1 — servidor CARLA
make run-carla

# terminal 2 — Autoware + interface (instala o wheel do carla no container e lança)
make run-autoware
```
`run-autoware` monta `~/autoware_data` em **`/root/autoware_data`** (data_path padrão, onde o Autoware
acha mapa **e** modelos), instala o wheel do CARLA (Python 3.10), conecta em `localhost:2000`, carrega o
**Town01**, spawna o ego e sobe perception→localization→planning→control. Headless por padrão; usa
`use_light_weight_sensor_mapping=true` (1 câmera). **Não interrompa** — a 1ª carga do Town01 é lenta.

**Validar headless** (noutro terminal) — pipeline confirmado quando:
```bash
docker ps    # nome do container do autoware
C=<NAME>
docker exec -it $C bash -lc 'source /opt/autoware/setup.bash
  ros2 node list | grep -i carla                                  # /autoware_carla_interface vivo
  ros2 topic hz /sensing/lidar/top/pointcloud_before_sync         # lidar do CARLA chegando (~5-11 Hz)
  ros2 topic echo /localization/kinematic_state --once'           # ego localizado (pose real)
```
Checagem direta do CARLA: `python3 -c "import carla; w=carla.Client('localhost',2000); ..."` deve
mostrar `map: Carla/Maps/Town01` e atores > 0.

## 8. Parte gráfica — ver e dirigir no rviz — ⏳
Dar o *goal pose* exige display. Como **não é AWS** (NICE DCV precisa de licença fora da AWS), usa-se
**desktop virtual (Xvfb) + VNC**, acessado por túnel SSH. Começa em **software GL** (simples); migra-se
para VirtualGL/GPU se ficar lento.

```bash
# na VM: sobe o desktop virtual + VNC (idempotente)
make desktop                    # Xvfb :99 + fluxbox + x11vnc em localhost:5900

# no SEU PC: túnel SSH + cliente VNC (TigerVNC/RealVNC) em localhost:5900
ssh -i ~/.ssh/SUA_CHAVE -L 5900:localhost:5900 <user>@<IP_DA_VM>

# na VM, com o CARLA rodando (make run-carla), sobe o Autoware COM rviz:
RVIZ=true make run-autoware     # encaminha o DISPLAY :99 para o container
```
No rviz (pela janela VNC): **2D Pose Estimate** (se não auto-inicializar) → **2D Goal Pose** → o ego
planeja a rota e dirige. Grave a tela = vídeo-entregável da Fase 0.

> Fontes da receita CARLA↔Autoware: [autoware_carla_interface (docs)](https://autowarefoundation.github.io/autoware_universe/main/simulator/autoware_carla_interface/)
> · mapas [CARLA Autoware Contents](https://bitbucket.org/carla-simulator/autoware-contents/src/master/maps/)
> · wheel [gezp/carla_ros](https://github.com/gezp/carla_ros/releases/tag/carla-0.9.15-ubuntu-22.04)
> · artefatos: playbook `autoware.dev_env.download_artifacts`.

## Objetivo da Fase 0
Ego **dirigindo sozinho** no CARLA via Autoware (perception → planning → control), **ainda sem
SOME/IP**. A ponte SOME/IP real é a Fase 1.

## Pausar a VM (custo)
Pare a VM quando não estiver usando. Em AWS/Azure/GCP/TensorDock/Hyperstack: **stop/deallocate** para
de cobrar o compute (paga só o disco). No **DigitalOcean**, desligado **continua cobrando** → snapshot
+ destroy.

## Status
**Fase 0 — pipeline validado headless** (numa RTX A6000): CARLA (Town01, ego + tráfego) → sensores →
Autoware → **ego localizado** (`kinematic_state` com pose real), com a `autoware_carla_interface` viva.
Marcos 3, 4, 5a, 5b, 5c, 7 ✓. Falta o marco 8: display remoto (VNC+VirtualGL) para dar o goal e gravar
o ego dirigindo.
