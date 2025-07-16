# # Dockerfile FINAL para MuJoCo no Ubuntu 24.04 (com correções de permissão robustas)
#
# Esta versão lida com UIDs/GIDs que já existem na imagem base, como o 1000.

# Etapa 1: Imagem Base e Argumentos de Build
FROM ubuntu:24.04

# Argumentos para passar o ID do usuário e do grupo do host para o build
ARG HOST_UID=1000
ARG HOST_GID=1000

# Etapa 2: Instalação de Dependências (incluindo libs para GUI e ferramentas de teste)
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt-get install -y --no-install-recommends \
    build-essential \
    python3 \
    python3-pip \
    python3-venv \
    libmujoco-dev \
    libgl1 \
    libegl1 \
    libopengl0 \
    libglfw3-dev \
    libglew-dev \
    git \
    wget \
    curl \
    ffmpeg \
    vim \
    pkg-config \
    libssl-dev \
    libgtk-3-dev \
    xauth \
    x11-apps \
    mesa-utils \
    sudo && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Etapa 3: Criar ou Modificar um Usuário para Corresponder ao UID/GID do Host
# Este script agora lida com conflitos de UID/GID, renomeando/modificando se necessário.
RUN export DEBIAN_FRONTEND=noninteractive \
    # Cria o grupo, se um com o GID não existir
    && if ! getent group $HOST_GID > /dev/null; then groupadd -g $HOST_GID mujoco_user; fi \
    # Garante que o usuário com o UID do host tenha o nome 'mujoco_user'
    && if getent passwd $HOST_UID > /dev/null; then \
        EXISTING_NAME=$(getent passwd $HOST_UID | cut -d: -f1); \
        if [ "$EXISTING_NAME" != "mujoco_user" ]; then \
            usermod -l mujoco_user -d /home/mujoco_user -m $EXISTING_NAME; \
        fi; \
    else \
        useradd -s /bin/bash -u $HOST_UID -g $HOST_GID -m mujoco_user; \
    fi \
    # Garante que o usuário tenha o GID correto e esteja no grupo sudo
    && usermod -g $HOST_GID mujoco_user \
    && usermod -aG sudo mujoco_user \
    && echo "mujoco_user ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/mujoco_user \
    && chmod 0440 /etc/sudoers.d/mujoco_user

# Etapa 4: Mudar para o Usuário e Configurar o Ambiente Python
# Agora que o usuário 'mujoco_user' GARANTIDAMENTE existe, podemos mudar para ele.
USER mujoco_user
WORKDIR /home/mujoco_user

# Cria o ambiente virtual e instala os pacotes como o próprio usuário,
# garantindo que as permissões dos arquivos fiquem corretas.
RUN python3 -m venv venv && \
    ./venv/bin/pip install --no-cache-dir --upgrade pip obj2mjcf && \
    ./venv/bin/pip install --no-cache-dir numpy mujoco gymnasium[mujoco] imageio matplotlib mujoco-py

# Adiciona o venv ao PATH do sistema
ENV PATH="/home/mujoco_user/venv/bin:$PATH"

# Etapa 5: Ponto de Entrada
CMD ["bash"]