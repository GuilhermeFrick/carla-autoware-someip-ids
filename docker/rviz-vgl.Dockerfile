# rviz do Autoware renderizado na GPU via VirtualGL (backend EGL), para VM headless com VNC.
# Base = mesma imagem do Autoware (já tem rviz2 + plugins + config). Só adiciona o VirtualGL.
FROM ghcr.io/autowarefoundation/autoware:universe-cuda

USER root
RUN apt-get update && apt-get install -y --no-install-recommends \
      wget ca-certificates libegl1 mesa-utils && \
    wget -qO /tmp/vgl.deb https://github.com/VirtualGL/virtualgl/releases/download/3.1.4/virtualgl_3.1.4_amd64.deb && \
    apt-get install -y /tmp/vgl.deb && rm /tmp/vgl.deb && \
    rm -rf /var/lib/apt/lists/*
