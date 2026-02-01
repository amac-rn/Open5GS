# Open5GS
Atividade da discplina TELCO CLOUD
Open5GS Docker Deployment para OpenRAN

# 📋 Visão Geral

Esse projeto é referemnte a implantação do 5G Core (Open5GS) com Docker para uso em um cenário OpenRAN.  A solução é reproduzível, escalável e pronta para ambientes de laboratório e desenvolvimento.

# 🎯 Objetivo

Implantar o 5G Core (Open5GS) como serviços cloud-native utilizando Docker Compose, garantindo:

* Reprodutibilidade do ambiente

* Prontidão para integração com RAN/UE

* Validação do funcionamento do core

* Base para futura migração para Kubernetes

# 🏗️ Arquitetura

```bash
┌────────────────────────────────────────────────────────────┐
│                Host Linux (Ubuntu 22.04+)                  │
├────────────────────────────────────────────────────────────┤
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐    │
│  │   AMF    │  │   SMF    │  │   UPF    │  │   NRF    │    │
│  │ (N2/SCTP)│  │ (N4/PFCP)│  │(N3/GTP-U)│  │ (SBI)    │    │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘    │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐    │
│  │   AUSF   │  │   UDM    │  │   PCF    │  │   UDR    │    │
│  │  (SBI)   │  │  (SBI)   │  │  (SBI)   │  │  (SBI)   │    │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘    │
│                     ┌─────────────┐                        │
│                     │  MongoDB    │                        │
│                     │ (Database)  │                        │
│                     └─────────────┘                        │
└────────────────────────────────────────────────────────────┘
```

# 📦 Componentes Implementados
|Serviço	| Função	                    | Portas Expostas | Protocolo   |
|-----------|-------------------------------|-----------------|-------------|
|MongoDB	| Banco de dados                | 27017 (interno) | TCP         |
|NRF	    | Network Repository Function	| 7777	          | HTTP        |
|AMF        | Access and Mobility Management| 38412, 9090	  | SCTP, HTTP  |
|SMF	    | Session Management Function	| 8805, 9080	  | UDP, HTTP   |
|UPF	    | User Plane Function	        | 2152, 8805	  | UDP         |
|AUSF	    | Authentication Server	        | 9088	          | HTTP        |
|UDM	    | Unified Data Management	    | 9087	          | HTTP        |
|PCF	    | Policy Control Function	    | 9089	          | HTTP        |
|UDR	    | Unified Data Repository	    | 9086	          | HTTP        |

# 🚀 Pré-requisitos


✅ SO: Ubuntu 22.04 LTS ou equivalente

✅ RAM: 4 GB mínimo (8 GB recomendado)

✅ CPU: 2 núcleos mínimo

✅ Armazenamento: 10 GB livre

✅ docker: versão superior a 20.10

✅ docker-compose versão superior a 2.0


# 📁 Estrutura do Projeto
```text

open5gs-docker/
├── docker-compose.yml
├── .env
├── README.md
├── scripts/
│   ├── start.sh
│   ├── stop.sh
│   └── health-check.sh
├── config/
│   └── open5gs/
│       ├── mongo-init.js
│       └── (configurações personalizadas)
└── logs/

```

# 🛠️ Instalação e Configuração
Instalar Docker e Docker Compose
```yaml

# Atualizar sistema
sudo apt update && sudo apt upgrade -y

# Instalar Docker
sudo apt install -y docker.io docker-compose

# Verificar a instalação
docker --version
docker-compose --version

# Adicionar usuário ao grupo docker (permite usar sem sudo)
sudo usermod -aG docker $USER
newgrp docker

# Habilitar Docker no boot
sudo systemctl enable docker
```

# Criar diretório do projeto
```bash
mkdir open5gs-docker && cd open5gs-docker
mkdir scripts logs config && cd config
mkdir open5gs
```
# Criar arquivo docker-compose.yml

Deverá ser criado o arquivo docker-compose.yml que ficará no diretório "open5gs-docker".  

Este aquivo ira automatizar a criação dos 9 containers conforme a estrutura definida no projeto.

Os containers são:

* open5gs-mongodb: Banco de dados da sulução

Alem destes, também é definida para aplicação uma rede do tipo bridge, nomeada de " 


```yaml
version: '3.9'

services:
  mongodb:
    image: mongo:6.0
    container_name: open5gs-mongodb
    restart: unless-stopped
    volumes:
      - mongodb_data:/data/db
      - ./config/open5gs/mongo-init.js:/docker-entrypoint-initdb.d/mongo-init.js:ro
    environment:
      - MONGO_INITDB_ROOT_USERNAME=${MONGO_USER}
      - MONGO_INITDB_ROOT_PASSWORD=${MONGO_PASSWORD}
    networks:
      - open5gs-net
    healthcheck:
      test: ["CMD", "mongosh", "--eval", "db.adminCommand('ping')"]
      interval: 30s
      timeout: 10s
      retries: 3

  open5gs-nrf:
    image: open5gs/open5gs:latest
    container_name: open5gs-nrf
    restart: unless-stopped
    command: nrf
    volumes:
      - ./config/open5gs:/open5gs/config
      - ./logs:/open5gs/logs
    environment:
      - MONGO_HOST=mongodb
      - MONGO_USER=${MONGO_USER}
      - MONGO_PASSWORD=${MONGO_PASSWORD}
    ports:
      - "7777:7777"  # SBI HTTP
    networks:
      - open5gs-net
    depends_on:
      mongodb:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:7777"]
      interval: 30s
      timeout: 10s
      retries: 3

  open5gs-amf:
    image: open5gs/open5gs:latest
    container_name: open5gs-amf
    restart: unless-stopped
    command: amf
    volumes:
      - ./config/open5gs:/open5gs/config
      - ./logs:/open5gs/logs
    ports:
      - "38412:38412/sctp"  # NGAP (N2)
      - "9090:9090"         # SBI HTTP
    networks:
      - open5gs-net
    depends_on:
      open5gs-nrf:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:9090"]
      interval: 30s
      timeout: 10s
      retries: 3

  open5gs-smf:
    image: open5gs/open5gs:latest
    container_name: open5gs-smf
    restart: unless-stopped
    command: smf
    volumes:
      - ./config/open5gs:/open5gs/config
      - ./logs:/open5gs/logs
    ports:
      - "8805:8805/udp"  # PFCP (N4)
      - "9080:9080"      # SBI HTTP
    networks:
      - open5gs-net
    depends_on:
      open5gs-nrf:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:9080"]
      interval: 30s
      timeout: 10s
      retries: 3

  open5gs-upf:
    image: open5gs/open5gs:latest
    container_name: open5gs-upf
    restart: unless-stopped
    command: upf
    volumes:
      - ./config/open5gs:/open5gs/config
      - ./logs:/open5gs/logs
    ports:
      - "2152:2152/udp"  # GTP-U (N3)
      - "8805:8805/udp"  # PFCP (N4)
    networks:
      - open5gs-net
    depends_on:
      open5gs-smf:
        condition: service_healthy
    cap_add:
      - NET_ADMIN
    sysctls:
      - net.ipv4.ip_forward=1
      - net.ipv6.conf.all.forwarding=1

  open5gs-ausf:
    image: open5gs/open5gs:latest
    container_name: open5gs-ausf
    restart: unless-stopped
    command: ausf
    volumes:
      - ./config/open5gs:/open5gs/config
      - ./logs:/open5gs/logs
    ports:
      - "9088:9088"  # SBI HTTP
    networks:
      - open5gs-net
    depends_on:
      open5gs-nrf:
        condition: service_healthy

  open5gs-udm:
    image: open5gs/open5gs:latest
    container_name: open5gs-udm
    restart: unless-stopped
    command: udm
    volumes:
      - ./config/open5gs:/open5gs/config
      - ./logs:/open5gs/logs
    ports:
      - "9087:9087"  # SBI HTTP
    networks:
      - open5gs-net
    depends_on:
      open5gs-nrf:
        condition: service_healthy

  open5gs-pcf:
    image: open5gs/open5gs:latest
    container_name: open5gs-pcf
    restart: unless-stopped
    command: pcf
    volumes:
      - ./config/open5gs:/open5gs/config
      - ./logs:/open5gs/logs
    ports:
      - "9089:9089"  # SBI HTTP
    networks:
      - open5gs-net
    depends_on:
      open5gs-nrf:
        condition: service_healthy

  open5gs-udr:
    image: open5gs/open5gs:latest
    container_name: open5gs-udr
    restart: unless-stopped
    command: udr
    volumes:
      - ./config/open5gs:/open5gs/config
      - ./logs:/open5gs/logs
    ports:
      - "9086:9086"  # SBI HTTP
    networks:
      - open5gs-net
    depends_on:
      open5gs-nrf:
        condition: service_healthy

networks:
  open5gs-net:
    driver: bridge
    ipam:
      config:
        - subnet: 10.100.0.0/16

volumes:
  mongodb_data:
```

# Resultados
Os resultados não foram conforme esperado.
Depois de executar o Docker compose, aparentemtene os comando para escução das funções do core (nrf, amf, smf, upf, udm, udr, ausf, pcf) não estavam encontrando o caminho correto no cotainer.  Apenas o banco de dados executou a funão normalmente.

Segue abaixo os print e logs da execução do docker composer.





Aluno: Alexandre Magno de Almeida Correia
Data: 01/02/2026
Ambiente Testado: Ubuntu 22.04 LTS, Docker 24.0, Docker Compose 2.20
