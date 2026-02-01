# Open5GS 5G Core - Implantação com Docker Customizado

Esta solução implementa um Core 5G completo usando Open5GS, construído a partir de uma imagem Docker personalizada baseada no Ubuntu, seguindo o tutorial oficial do Open5GS.

## 📋 Pré-requisitos

### Sistema Operacional
- Ubuntu 22.04 LTS ou superior
- 4GB RAM mínimo (8GB recomendado)
- 20GB de espaço em disco
- Conexão de internet

### Software Necessário
- Docker Engine 20.10+
- Docker Compose 2.0+
- Git (para clonar o repositório)

## 🚀 Instalação Rápida

### 1. Instalar Docker e Docker Compose

```bash
# Atualizar sistema
sudo apt update && sudo apt upgrade -y

# Instalar Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Adicionar usuário ao grupo docker
sudo usermod -aG docker $USER
newgrp docker

# Instalar Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Verificar instalação
docker --version
docker-compose --version
