# Dockerfile Simples para Open5GS
FROM ubuntu:22.04

# Configuração básica
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC
ENV LD_LIBRARY_PATH=/usr/local/lib

# Atualizar e instalar dependências
RUN apt-get update && apt-get install -y \
    git \
    build-essential \
    cmake \
    ninja-build \
    pkg-config \
    autoconf \
    automake \
    libtool \
    python3 \
    python3-pip \
    python3-dev \
    libsctp-dev \
    libgnutls28-dev \
    libgcrypt-dev \
    libssl-dev \
    libidn11-dev \
    libmongoc-dev \
    libbson-dev \
    libyaml-dev \
    libnghttp2-dev \
    libmicrohttpd-dev \
    libcurl4-gnutls-dev \
    libtalloc-dev \
    libpcsclite-dev \
    libsystemd-dev \
    libmnl-dev \
    wget \
    flex \
    bison \
    curl \
    gnupg \
    && rm -rf /var/lib/apt/lists/*

# Instalar meson via pip
RUN pip3 install meson

# Adicionar MongoDB repo
RUN wget -qO - https://www.mongodb.org/static/pgp/server-6.0.asc | gpg --dearmor -o /usr/share/keyrings/mongodb-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/mongodb-archive-keyring.gpg] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/6.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-6.0.list

# Instalar MongoDB
RUN apt-get update && apt-get install -y \
    mongodb-org \
    mongodb-org-server \
    && rm -rf /var/lib/apt/lists/*

# Clonar e compilar Open5GS
WORKDIR /build
RUN git clone --depth 1 https://github.com/open5gs/open5gs.git
WORKDIR /build/open5gs
RUN git submodule update --init --recursive
RUN meson setup build --prefix=/usr/local
RUN ninja -C build
RUN ninja -C build install

# Configurar bibliotecas
RUN echo "/usr/local/lib" > /etc/ld.so.conf.d/open5gs.conf && ldconfig

# Criar diretórios
RUN mkdir -p /etc/open5gs /var/log/open5gs /data/db

# Script de entrada simplificado
RUN echo '#!/bin/bash\n\
if [ "$1" = "bash" ]; then\n\
    exec /bin/bash\n\
else\n\
    echo "Open5GS Docker Image"\n\
    echo "Available commands: nrf, amf, smf, upf, udm, udr, ausf, pcf"\n\
    echo "Example: docker run open5gs-custom nrf"\n\
fi' > /entrypoint.sh && chmod +x /entrypoint.sh

# Portas
EXPOSE 7777 38412 9090 8080 8805 2152

ENTRYPOINT ["/entrypoint.sh"]
