#!/bin/bash
# start.sh

echo "=========================================="
echo "Iniciando Open5GS 5G Core Network"
echo "=========================================="

# Verificar se Docker Compose está disponível
if ! command -v docker-compose &> /dev/null && ! command -v docker &> /dev/null; then
    echo " Docker não encontrado. Por favor, instale o Docker primeiro."
    exit 1
fi

# Verificar se docker compose está disponível
if command -v docker-compose &> /dev/null; then
    DOCKER_COMPOSE_CMD="docker-compose"
elif docker compose version &> /dev/null; then
    DOCKER_COMPOSE_CMD="docker compose"
else
    echo " Docker Compose não encontrado."
    exit 1
fi

# Carregar variáveis de ambiente
if [ -f .env ]; then
    echo "Carregando variáveis de ambiente do arquivo .env"
    export $(cat .env | grep -v '^#' | xargs)
else
    echo "⚠️  Arquivo .env não encontrado. Usando valores padrão."
fi

# Criar diretórios de configuração
echo "Criando diretórios de configuração..."
mkdir -p config/open5gs
mkdir -p logs

# Verificar se os arquivos de configuração existem
echo "Verificando arquivos de configuração..."
if [ ! -f "config/open5gs/nrf.yaml" ]; then
    echo "Criando configurações padrão..."
    # (Os arquivos YAML serão criados se não existirem)
    cp -n config/open5gs/nrf.yaml.example config/open5gs/nrf.yaml 2>/dev/null || true
fi

# Construir imagens se necessário
echo "Construindo/atualizando imagens Docker..."
$DOCKER_COMPOSE_CMD build

# Iniciar serviços
echo ""
echo "Iniciando serviços Open5GS..."
$DOCKER_COMPOSE_CMD up -d

echo ""
echo "Aguardando inicialização dos serviços..."
sleep 15

# Verificar status
echo ""
echo "=========================================="
echo "Status dos Serviços"
echo "=========================================="
$DOCKER_COMPOSE_CMD ps

# Verificar saúde dos serviços
echo ""
echo "=========================================="
echo "Verificação de Saúde"
echo "=========================================="

check_service() {
    local service=$1
    local port=$2
    local endpoint=$3
    
    if curl -s -f http://localhost:$port$endpoint > /dev/null 2>&1; then
        echo " $service está respondendo na porta $port"
        return 0
    else
        echo " $service não está respondendo na porta $port"
        return 1
    fi
}

echo ""
echo "Testando conectividade dos serviços:"

# Testar NRF
check_service "NRF" "$NRF_PORT" "/nnrf-nfm/v1/nf-instances"

# Testar AMF
check_service "AMF" "9090" ""

# Testar SMF
check_service "SMF" "8080" ""

# Testar UDM
check_service "UDM" "8000" ""

# Verificar portas SCTP
echo ""
echo "Verificando portas SCTP..."
if ss -tulpn | grep -q ":${AMF_NGAP_PORT}"; then
    echo " Porta SCTP ${AMF_NGAP_PORT} está ouvindo"
else
    echo " Porta SCTP ${AMF_NGAP_PORT} não está disponível"
fi

# Verificar portas GTP-U
echo ""
echo "Verificando portas GTP-U..."
if ss -tulpn | grep -q ":${UPF_GTPU_PORT}"; then
    echo " Porta GTP-U ${UPF_GTPU_PORT} está ouvindo"
else
    echo " Porta GTP-U ${UPF_GTPU_PORT} não está disponível"
fi

echo ""
echo "=========================================="
echo "Resumo das Portas Expostas"
echo "=========================================="
echo "Interface       | Porta      | Protocolo | Finalidade"
echo "----------------|------------|-----------|-----------------"
echo "NGAP (RAN)      | 38412      | SCTP      | Conexão com RAN"
echo "GTP-U (Plano D) | 2152       | UDP       | Plano de dados"
echo "NRF SBI         | 7777       | HTTP      | Registro NF"
echo "AMF SBI         | 9090       | HTTP      | API AMF"
echo "SMF SBI         | 8080       | HTTP      | API SMF"
echo "UPF PFCP        | 8805       | UDP       | Controle UPF"
echo "UDM SBI         | 8000       | HTTP      | Gerenciamento UE"
echo "UDR SBI         | 7000       | HTTP      | Repositório Dados"
echo "AUSF SBI        | 6000       | HTTP      | Autenticação"
echo "PCF SBI         | 5555       | HTTP      | Políticas"

echo ""
echo "=========================================="
echo "Próximos Passos"
echo "=========================================="
echo "1. Ver logs:                docker-compose logs -f [serviço]"
echo "2. Parar serviços:          ./stop.sh"
echo "3. Acessar MongoDB:         docker exec -it open5gs-mongodb mongo"
echo "4. Testar API NRF:          curl http://localhost:7777/nnrf-nfm/v1/nf-instances"
echo ""
echo " Open5GS 5G Core está em execução!"
