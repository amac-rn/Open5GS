#!/bin/bash
# stop.sh

echo "=========================================="
echo "Parando Open5GS 5G Core Network"
echo "=========================================="

# Verificar se docker compose está disponível
if command -v docker-compose &> /dev/null; then
    DOCKER_COMPOSE_CMD="docker-compose"
elif docker compose version &> /dev/null; then
    DOCKER_COMPOSE_CMD="docker compose"
else
    echo " Docker Compose não encontrado."
    exit 1
fi

echo "Parando e removendo containers..."
$DOCKER_COMPOSE_CMD down

echo ""
echo "Removendo networks não utilizadas..."
docker network prune -f

echo ""
echo " Ambiente Open5GS parado com sucesso!"
