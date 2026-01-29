# Open5GS
Atividade da discplina TELCO CLOUD
Open5GS Docker Deployment para OpenRAN

# 📋 Visão Geral

Esse projeto é referemnte a implantação do 5G Core (Open5GS) com Docker para uso em um cenário OpenRAN.  A solução é reproduzível, escalável e pronta para ambientes de laboratório e desenvolvimento.

# 🎯 Objetivo

Implantar o 5G Core (Open5GS) como serviços cloud-native utilizando Docker Compose, garantindo:

    ✅ Reprodutibilidade do ambiente

    ✅ Prontidão para integração com RAN/UE

    ✅ Validação do funcionamento do core

    ✅ Base para futura migração para Kubernetes

🏗️ Arquitetura
text

┌─────────────────────────────────────────────────────────────┐
│                    Host Linux (Ubuntu 22.04+)               │
├─────────────────────────────────────────────────────────────┤
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
│  │   AMF    │  │   SMF    │  │   UPF    │  │   NRF    │   │
│  │ (N2/SCTP)│  │ (N4/PFCP)│  │(N3/GTP-U)│  │ (SBI)    │   │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘   │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
│  │   AUSF   │  │   UDM    │  │   PCF    │  │   UDR    │   │
│  │  (SBI)   │  │  (SBI)   │  │  (SBI)   │  │  (SBI)   │   │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘   │
│                     ┌─────────────┐                        │
│                     │  MongoDB    │                        │
│                     │ (Database)  │                        │
│                     └─────────────┘                        │
└─────────────────────────────────────────────────────────────┘

📦 Componentes Implementados
Serviço	Função	Portas Expostas	Protocolo
MongoDB	Banco de dados	27017 (interno)	TCP
NRF	Network Repository Function	7777	HTTP
AMF	Access and Mobility Management	38412, 9090	SCTP, HTTP
SMF	Session Management Function	8805, 9080	UDP, HTTP
UPF	User Plane Function	2152, 8805	UDP
AUSF	Authentication Server	9088	HTTP
UDM	Unified Data Management	9087	HTTP
PCF	Policy Control Function	9089	HTTP
UDR	Unified Data Repository	9086	HTTP
🚀 Pré-requisitos
Sistema

    SO: Ubuntu 22.04 LTS ou equivalente

    RAM: 4 GB mínimo (8 GB recomendado)

    CPU: 2 núcleos mínimo

    Armazenamento: 10 GB livre

Software
bash

# Verificar versões mínimas
docker --version        # >= 20.10
docker-compose --version # >= 2.0

⚡ Instalação Rápida
1. Clone e prepare o ambiente
bash

# Clone o repositório
git clone <repositorio>
cd open5gs-docker

# Dê permissões de execução
chmod +x scripts/*.sh

2. Execute o script de inicialização
bash

# Inicie todos os serviços
./scripts/start.sh

3. Valide o funcionamento
bash

# Execute health check
./scripts/health-check.sh

🔧 Configuração Manual
Passo 1: Instalar Docker e Docker Compose
bash

# Atualizar sistema
sudo apt update && sudo apt upgrade -y

# Instalar Docker
sudo apt install -y docker.io docker-compose

# Adicionar usuário ao grupo docker
sudo usermod -aG docker $USER
newgrp docker

# Testar instalação
docker --version
docker-compose --version

Passo 2: Configurar o Ambiente
bash

# Criar diretório do projeto
mkdir -p open5gs-docker/{config/open5gs,scripts,logs}
cd open5gs-docker

# Copiar arquivos de configuração
# (docker-compose.yml, .env, scripts/)

Passo 3: Configurar Variáveis de Ambiente
bash

# Editar arquivo .env conforme necessidade
nano .env

Conteúdo mínimo do .env:
env

MONGO_USER=open5gs
MONGO_PASSWORD=open5gs
MCC=999
MNC=70
TAC=7

Passo 4: Iniciar os Serviços
bash

# Subir todos os containers
docker-compose up -d

# Verificar status
docker-compose ps

✅ Validação do Funcionamento
Teste 1: Verificar Containers
bash

# Listar containers em execução
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

Saída esperada:
text

NAMES             STATUS         PORTS
open5gs-nrf       Up 5 minutes   0.0.0.0:7777->7777/tcp
open5gs-amf       Up 5 minutes   0.0.0.0:38412->38412/sctp, 0.0.0.0:9090->9090/tcp
open5gs-smf       Up 5 minutes   0.0.0.0:8805->8805/udp, 0.0.0.0:9080->9080/tcp
open5gs-upf       Up 5 minutes   0.0.0.0:2152->2152/udp
open5gs-mongodb   Up 5 minutes   27017/tcp

Teste 2: Verificar Portas
bash

# Verificar portas abertas
sudo netstat -tulpn | grep -E '(7777|38412|9090|9080|2152)'

Teste 3: Testar Conectividade HTTP
bash

# Testar NRF
curl -v http://localhost:7777/ -o /dev/null -s -w "NRF Status: %{http_code}\n"

# Testar AMF
curl -v http://localhost:9090/ -o /dev/null -s -w "AMF Status: %{http_code}\n"

# Testar SMF
curl -v http://localhost:9080/ -o /dev/null -s -w "SMF Status: %{http_code}\n"

Teste 4: Verificar Logs
bash

# Verificar logs de inicialização
docker-compose logs --tail=20 open5gs-nrf

# Procurar por erros
docker-compose logs | grep -i error | head -10

🛠️ Scripts de Automação
scripts/start.sh
bash

# Inicia todos os serviços e mostra status
./scripts/start.sh

scripts/stop.sh
bash

# Para todos os serviços e limpa recursos
./scripts/stop.sh

scripts/health-check.sh
bash

# Executa verificações completas de saúde
./scripts/health-check.sh

scripts/reset.sh (Opcional)
bash

# Reseta completamente o ambiente
./scripts/reset.sh

📊 Evidências de Funcionamento
1. Screenshot - Containers em Execução

https://evidencias/docker-ps.png
2. Screenshot - Logs de Inicialização

https://evidencias/open5gs-logs.png
3. Screenshot - Testes de Conectividade

https://evidencias/http-tests.png
4. Screenshot - Portas Abertas

https://evidencias/open-ports.png
🔍 Solução de Problemas
Problema: Portas em conflito
bash

# Verificar qual processo está usando a porta
sudo lsof -i :7777

# Alternativa: mudar porta no docker-compose.yml
# Porta 7777 → 7778

Problema: Containers não iniciam
bash

# Verificar logs detalhados
docker-compose logs --tail=50

# Verificar espaço em disco
df -h

# Verificar memória disponível
free -h

Problema: MongoDB não conecta
bash

# Verificar se MongoDB está saudável
docker-compose exec mongodb mongosh --eval "db.adminCommand('ping')"

# Reiniciar somente MongoDB
docker-compose restart mongodb

Problema: Erros de permissão
bash

# Verificar permissões do socket Docker
ls -la /var/run/docker.sock

# Corrigir se necessário
sudo chmod 666 /var/run/docker.sock

📝 Configurações Personalizadas
Modificar PLMN (Public Land Mobile Network)
env

# No arquivo .env
MCC=001  # Mobile Country Code
MNC=01   # Mobile Network Code
TAC=1    # Tracking Area Code

Configurar IPs dos Serviços
yaml

# No docker-compose.yml, serviço open5gs-amf:
ports:
  - "38412:38412/sctp"
  # Para mudar porta externa:
  - "38413:38412/sctp"  # Porta externa 38413, interna 38412

Adicionar Health Checks Personalizados
yaml

healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:7777/nrf/v1/nf-instances"]
  interval: 30s
  timeout: 10s
  retries: 3
  start_period: 40s

🚀 Próximos Passos
Integração com OpenRAN

    Configurar gNB (UERANSIM)
    bash

    # Exemplo de configuração do gNB
    # Conectar ao AMF em localhost:38412

    Configurar UE Simulado
    bash

    # Exemplo de comando UE
    ./nr-ue -c ue-config.yaml

    Validar Registro
    bash

    # Verificar logs do AMF para registro UE
    docker-compose logs open5gs-amf --tail=50

Monitoramento

    Adicionar Prometheus
    yaml

    # Adicionar ao docker-compose.yml
    prometheus:
      image: prom/prometheus
      ports:
        - "9091:9090"

    Adicionar Grafana
    yaml

    grafana:
      image: grafana/grafana
      ports:
        - "3000:3000"

Segurança

    Habilitar TLS
    bash

    # Gerar certificados
    openssl req -new -newkey rsa:2048 -days 365 -nodes -x509 \
      -keyout server.key -out server.crt

    Configurar Firewall
    bash

    # Permitir apenas portas necessárias
    sudo ufw allow 38412/sctp
    sudo ufw allow 7777/tcp

📚 Referências
Documentação Oficial

    Open5GS Documentation

    Docker Documentation

    3GPP Specifications

Repositórios Relacionados

    Open5GS GitHub

    UERANSIM

    O-RAN SC

Artigos e Tutoriais

    5G Core Network Architecture

    OpenRAN Architecture

    Cloud Native 5G

👥 Contribuição
Reportar Problemas

    Verifique se o problema já foi reportado

    Inclua informações:

        Comandos executados

        Logs relevantes

        Configuração do ambiente

        Screenshots (se aplicável)

Sugerir Melhorias

    Fork do repositório

    Crie uma branch (git checkout -b feature/melhoria)

    Commit das mudanças (git commit -m 'Add some feature')

    Push para a branch (git push origin feature/melhoria)

    Abra um Pull Request

📄 Licença

Este projeto é disponibilizado para fins educacionais e de laboratório.

    Open5GS: Licenciado sob AGPLv3

    Configurações Docker: MIT License

    Scripts: MIT License

AVISO: Esta configuração não é para uso em produção. Implemente medidas de segurança apropriadas antes de usar em ambientes reais.
🏆 Entrega do Desafio
Critérios de Avaliação

    Docker Compose funcional

    Todos os serviços principais em execução

    Portas expostas corretamente

    Health checks implementados

    Documentação completa

    Reprodutibilidade garantida

Evidências Incluídas

    docker-compose.yml - Configuração completa

    README.md - Documentação passo a passo

    Scripts de automação

    Screenshots de validação

    Configurações de ambiente

Desafio concluído por: [Seu Nome]
Data: [Data de Conclusão]
Ambiente Testado: Ubuntu 22.04 LTS, Docker 24.0, Docker Compose 2.20
