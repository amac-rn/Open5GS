#!/bin/bash
# validate.sh

echo "=========================================="
echo "Validação do Ambiente Open5GS"
echo "=========================================="

# Carregar variáveis de ambiente
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

# Verificar se Docker está rodando
if ! docker info > /dev/null 2>&1; then
    echo " Docker não está rodando"
    exit 1
fi

echo "✅ Docker está rodando"

# Verificar containers
echo ""
echo "Containers em execução:"
docker ps --filter "name=open5gs" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Verificar redes
echo ""
echo "Redes Docker:"
docker network ls --filter "name=open5gs" --format "table {{.Name}}\t{{.Driver}}\t{{.Scope}}"

# Testar conectividade
echo ""
echo "Testando conectividade dos serviços:"

services=(
    "mongodb:27017"
    "nrf:7777"
    "amf:9090"
    "smf:8080"
    "udm:8000"
)

for service in "${services[@]}"; do
    name=$(echo $service | cut -d: -f1)
    port=$(echo $service | cut -d: -f2)
    
    if docker exec open5gs-$name curl -s -f http://localhost:$port > /dev/null 2>&1; then
        echo " open5gs-$name está respondendo"
    else
        echo " open5gs-$name não está respondendo"
    fi
done

# Verificar logs de inicialização
echo ""
echo "Últimas linhas dos logs do NRF:"
docker logs --tail=10 open5gs-nrf 2>&1 | grep -E "(NRF|error|failed)" || echo "Nenhum log relevante encontrado"

# Verificar subscriber no MongoDB
echo ""
echo "Verificando subscriber no MongoDB..."
docker exec open5gs-mongodb mongo --eval "
db = db.getSiblingDB('open5gs');
count = db.subscribers.countDocuments({});
print('Total de subscribers:', count);
if (count > 0) {
    print('Primeiro subscriber:');
    db.subscribers.findOne({}, {imsi: 1, security: 0});
}
" 2>/dev/null || echo "Não foi possível acessar o MongoDB"

echo ""
echo "=========================================="
echo "Validação Completa"
echo "=========================================="
