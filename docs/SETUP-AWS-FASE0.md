# Setup AWS — Fase 0 (piloto: CARLA dirigido pelo Autoware)

Runbook para subir o ambiente pesado **na AWS** e obter o entregável da Fase 0: o ego
dirigindo sozinho no CARLA via Autoware (perception → planning → control), **ainda sem
SOME/IP**. Decisão travada: rodar em **instância GPU na AWS** (não WSL2 / não bare-metal).

> Convenção deste repo: **você roda no Ubuntu e cola os logs**; o código/config é escrito
> aqui. Nada de executar CARLA/Autoware/GPU do lado Windows.

---

## 0. Visão geral e ordem de execução

```
[1] Provisionar instância GPU (Ubuntu 22.04 + driver NVIDIA + Docker + nvidia-container-toolkit)
[2] Acesso remoto com vídeo (NICE DCV) para ver rviz2/CARLA
[3] Validar GPU no host e dentro do Docker
[4] Instalar Autoware Universe (via Docker) + baixar mapas/artefatos
[5] Instalar CARLA 0.9.15 (tarball) + Python API
[6] Ponte autoware_carla_interface (CARLA 0.9.15 ⇄ Autoware)
[7] Rodar o piloto: CARLA headless + Autoware + interface → ego dirige
[8] Gravar o vídeo (entregável) + custos / desligar / snapshot
```

O **maior risco do projeto** está nos passos [4]–[7] (estabilizar Autoware+CARLA+GPU). Por
isso a Fase 0 existe isolada. Avançamos passo a passo, validando cada um pelo log.

---

## 1. Provisionar a instância GPU

### 1.1 Escolha da instância

| Instância | GPU | VRAM | vCPU | RAM | Uso |
|---|---|---|---|---|---|
| **g5.2xlarge** (recomendada) | A10G | 24 GB | 8 | 32 GB | CARLA + perception juntos com folga |
| g5.xlarge | A10G | 24 GB | 4 | 16 GB | funciona; RAM/CPU mais apertados |
| g4dn.2xlarge (econômica) | T4 | 16 GB | 8 | 32 GB | ok para começar; VRAM no limite |

- **Região:** escolha uma com boa oferta de `g5` (ex.: `us-east-1`). GPU exige **cota de vCPU
  de instâncias G/VT On-Demand** — se a conta é nova, provavelmente é 0. Abra
  *Service Quotas → EC2 → "Running On-Demand G and VT instances"* e peça ≥ 8 vCPU **antes**
  (aprovação pode levar horas).
- **Custo (ordem de grandeza, on-demand):** g5.2xlarge ~US$1,2/h; g4dn.2xlarge ~US$0,75/h.
  **Desligue quando não estiver usando** (ver §8). Considere *Spot* para reduzir ~60–70%.

### 1.2 AMI

Use a **Deep Learning Base OSS Nvidia Driver GPU AMI (Ubuntu 22.04)**, variante **64-bit (x86)** —
já vem com **driver NVIDIA**, **Docker** e **NVIDIA Container Toolkit** prontos, que é exatamente o
que o Autoware precisa. No console: *Launch instance → AMIs → busque* exatamente
`Deep Learning Base OSS Nvidia Driver GPU AMI (Ubuntu 22.04)` (se não aparecer no *Quick Start*,
clique em **Browse more AMIs**). A variante "…GPU PyTorch 2.x (Ubuntu 22.04)" também serve, mas é
bem mais pesada.

> **Não** use: **Amazon Linux 2023** (não tem ROS2 Humble), qualquer AMI **Arm64** (sem build de
> CARLA/Autoware), nem imagens Ubuntu 20.04 (ROS2 Humble é 22.04).
>
> Alternativa (Ubuntu 22.04 puro): buscar **"Ubuntu Server 22.04 LTS"** (Canonical), 64-bit x86, e
> instalar driver + docker + toolkit à mão (§3.4). Mais passos e mais chance de erro; só se a AMI
> acima não estiver disponível na região.

### 1.3 Storage

- **Raiz gp3 de 250 GB** (CARLA ~20 GB, imagens Docker do Autoware dezenas de GB, mapas).
  IOPS/throughput padrão do gp3 bastam.

### 1.4 Security Group (portas)

| Porta | Protocolo | Origem | Para quê |
|---|---|---|---|
| 22 | TCP | **seu IP /32** | SSH |
| 8443 | TCP | **seu IP /32** | NICE DCV (desktop remoto com GPU) |

> Nunca `0.0.0.0/0`. Restrinja ao seu IP. CARLA/ROS2 ficam internos à instância — não expor.

### 1.5 Criar (console ou CLI)

**Console:** Launch instance → nome `fase0-autoware-carla` → AMI (§1.2) → tipo `g5.2xlarge`
→ key pair (crie e guarde o `.pem`) → Network: security group (§1.4) → Storage: 250 GB gp3 →
Launch.

**CLI (opcional — ajuste os IDs):**
```bash
aws ec2 run-instances \
  --image-id ami-XXXXXXXX \                 # ID da DL Base GPU AMI (Ubuntu 22.04) na sua região
  --instance-type g5.2xlarge \
  --key-name SUA_KEY \
  --security-group-ids sg-XXXXXXXX \
  --block-device-mappings '[{"DeviceName":"/dev/sda1","Ebs":{"VolumeSize":250,"VolumeType":"gp3"}}]' \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=fase0-autoware-carla}]'
```

Acesso SSH:
```bash
ssh -i SUA_KEY.pem ubuntu@<IP_PUBLICO>
```

---

## 2. Acesso remoto com vídeo (NICE DCV)

CARLA roda **headless** (`-RenderOffScreen`), mas para **ver** o rviz2 e a câmera do CARLA
precisamos de desktop remoto com aceleração de GPU. **NICE DCV** é gratuito em EC2 e feito
para isso.

```bash
# no host (Ubuntu da instância)
sudo apt-get update
# instalar um desktop leve para o DCV servir
sudo apt-get install -y ubuntu-desktop-minimal   # ou xfce4, mais leve

# baixar e instalar o servidor NICE DCV (ver versão atual na doc AWS)
# https://docs.aws.amazon.com/dcv/latest/adminguide/setting-up-installing-linux-server.html
# depois de instalar:
sudo systemctl enable --now dcvserver
# criar sessão virtual do usuário ubuntu:
dcv create-session fase0 --owner ubuntu
```

Cliente DCV (baixe em https://download.nice-dcv.com) → conecte em `https://<IP>:8443`,
sessão `fase0`, usuário `ubuntu` (defina senha com `sudo passwd ubuntu`).

> Cole aqui o log de `dcv list-sessions` e da conexão se algo falhar.

---

## 3. Validar GPU (host e Docker)

```bash
# host
nvidia-smi                      # deve listar a A10G/T4 e a versão do driver

# Docker enxerga a GPU?
docker run --rm --gpus all nvidia/cuda:12.2.0-base-ubuntu22.04 nvidia-smi
```

Se ambos mostram a GPU, a base está ok. **Cole os dois outputs.**

### 3.4 (Só se usou Ubuntu puro em vez da DL AMI)
```bash
# driver NVIDIA
sudo apt-get update && sudo ubuntu-drivers install
# Docker
curl -fsSL https://get.docker.com | sh && sudo usermod -aG docker $USER
# NVIDIA Container Toolkit
distribution=$(. /etc/os-release; echo $ID$VERSION_ID)
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list | \
  sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
  sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
sudo apt-get update && sudo apt-get install -y nvidia-container-toolkit
sudo nvidia-ctk runtime configure --runtime=docker && sudo systemctl restart docker
# reinicie a sessão SSH para o grupo docker valer
```

---

## 4. Autoware Universe (via Docker)

Caminho oficial recomendado (imagem pronta + `rocker` para GPU/X):

```bash
cd ~
git clone https://github.com/autowarefoundation/autoware.git
cd autoware

# prepara o host (ansible): rocker, dependências de container, etc.
./setup-dev-env.sh -y docker

# baixar imagem do Autoware Universe + artefatos de mapa de exemplo
mkdir -p ~/autoware_map
# mapa de exemplo (sample-map-planning) — link na doc do Autoware:
# https://autowarefoundation.github.io/autoware-documentation/main/tutorials/
```

Rodar o container (com GPU e X para o rviz2 aparecer no DCV):
```bash
cd ~/autoware
./docker/run.sh --map-path ~/autoware_map
# dentro do container, um smoke test do planning simulator:
# ros2 launch autoware_launch planning_simulator.launch.xml \
#   map_path:=$HOME/autoware_map vehicle_model:=sample_vehicle sensor_model:=sample_sensor_kit
```

**Marco de validação [4]:** o *planning simulator* do Autoware abre no rviz2 (via DCV) com um
mapa de exemplo, **sem CARLA ainda**. Cole o log do `./docker/run.sh` e um print do rviz2.

> Notas: nomes exatos de launch/imagem podem mudar conforme a tag do `autoware` que
> clonarmos. Se um comando falhar, cole o erro — ajusto para a versão que baixou.

---

## 5. CARLA 0.9.15

Versão **fixada em 0.9.15** de propósito: é a suportada pela ponte do §6.

```bash
cd ~
mkdir carla && cd carla
# tarball do release 0.9.15 (GitHub releases do carla-simulator):
wget https://github.com/carla-simulator/carla/releases/download/0.9.15/CARLA_0.9.15.tar.gz
tar -xzf CARLA_0.9.15.tar.gz

# smoke test headless (sem abrir janela, render off-screen via Vulkan):
./CarlaUE4.sh -RenderOffScreen -quality-level=Low -nosound &
# em outro terminal, testar a API Python:
python3 -m pip install carla==0.9.15
python3 PythonAPI/examples/generate_traffic.py -n 10   # deve conectar em localhost:2000
```

**Marco de validação [5]:** CARLA sobe headless e um script de exemplo conecta na porta 2000.
Cole o log do `CarlaUE4.sh` (procure por `4.26` / `LogCarla` / erros de Vulkan) e do
`generate_traffic.py`.

> Se der erro de Vulkan/driver: normalmente é driver NVIDIA ou falta de `libvulkan1`
> (`sudo apt-get install -y libvulkan1 vulkan-tools && vulkaninfo | head`). Cole o erro.

---

## 6. Ponte CARLA 0.9.15 ⇄ Autoware (`autoware_carla_interface`)

O Autoware Universe traz um pacote de interface para CARLA (Python, baseado na API do CARLA)
em `simulator/` — direcionado ao **CARLA 0.9.15**. É por isso que o CARLA está pinado nessa
versão. Fluxo geral:

1. Dentro do workspace do Autoware, garantir o pacote da interface CARLA compilado
   (`autoware_carla_interface` / pasta `simulator/carla_autoware`).
2. Subir CARLA headless (§5).
3. Lançar a interface, que instancia o ego no CARLA, publica sensores como tópicos ROS2 e
   assina `/control/command` para aplicar controle no CARLA (loop de controle da Fase 0).

```bash
# dentro do container Autoware, no workspace já buildado:
# (nomes exatos confirmados contra a tag que clonarmos — iteramos por log)
ros2 launch autoware_carla_interface carla_autoware.launch.xml
```

**Ponto de maior incerteza do runbook.** O nome do pacote/launch e os requisitos Python
(ex.: versão do `carla` egg, `numpy`, `transforms3d`) variam com a versão. **Estratégia:**
cole o `ros2 pkg list | grep carla`, a árvore de `simulator/` do autoware clonado e qualquer
erro de launch — a partir daí escrevo o launch/params exatos.

---

## 7. Rodar o piloto (ego dirigindo)

Ordem de subida (3 terminais / tmux dentro da instância):

```bash
# T1 — CARLA headless
cd ~/carla && ./CarlaUE4.sh -RenderOffScreen -quality-level=Low -nosound

# T2 — Autoware + interface CARLA (dentro do container)
cd ~/autoware && ./docker/run.sh --map-path ~/autoware_map
#   dentro: ros2 launch autoware_carla_interface carla_autoware.launch.xml

# T3 — rviz2 (via DCV) para definir goal pose e ver perception/planning
```

Fluxo do teste: no rviz2, definir *initial pose* e *goal pose* → o Autoware calcula rota →
`planning`/`control` geram comando → a interface aplica no ego do CARLA → **o carro anda**.

**Entregável da Fase 0:** vídeo do ego percorrendo o mapa (perception→planning→control) com
os tópicos ROS2 vivos (`ros2 topic hz /control/command`, `/localization/kinematic_state`,
`/perception/...`).

---

## 8. Custos, desligar e snapshot

- **Parar (stop) ≠ terminar (terminate):** *stop* preserva o disco (paga só EBS ~US$0,02/GB-mês,
  ~US$5/mês por 250 GB) e para de cobrar a GPU. Use *stop* ao fim de cada sessão.
- **Snapshot** do volume após o ambiente estar montado — se precisar recriar a instância,
  parte de uma AMI própria já com Autoware+CARLA e economiza horas.
- **Terminate** só quando encerrar a fase (perde o disco se não houver snapshot/AMI).
- Alarme de billing / Budget para não ter surpresa.

```bash
# criar AMI própria com tudo instalado (a partir da instância parada):
aws ec2 create-image --instance-id i-XXXX --name "fase0-autoware-carla-baseline"
```

---

## Marcos (checklist para colar logs)

- [ ] [3] `nvidia-smi` no host **e** no Docker mostram a GPU.
- [ ] [4] Planning simulator do Autoware abre no rviz2 (sem CARLA).
- [ ] [5] CARLA 0.9.15 sobe headless; exemplo Python conecta na 2000.
- [ ] [6] `autoware_carla_interface` lança sem erro; ego aparece no CARLA.
- [ ] [7] Ego dirige do initial ao goal pose. **Vídeo gravado.**

Cada marco é um ponto de parada para colar log — não avance com um marco vermelho.
