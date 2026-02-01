#!/bin/bash
# build-image.sh

echo "=========================================="
echo "Construindo imagem Docker do Open5GS"
echo "=========================================="

# Carregar variáveis de ambiente
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

# Nome da imagem
IMAGE_NAME="${DOCKER_REGISTRY}/open5gs-custom:${IMAGE_TAG}"

echo "Construindo imagem: $IMAGE_NAME"
echo "Contexto de build: $BUILD_CONTEXT"

# Construir a imagem
docker build -t $IMAGE_NAME $BUILD_CONTEXT

# Verificar se a construção foi bem-sucedida
if [ $? -eq 0 ]; then
    echo ""
    echo " Imagem construída com sucesso!"
    echo ""
    echo "Imagens disponíveis:"
    docker images | grep open5gs
    
    echo ""
    echo "Para executar o ambiente:"
    echo "  ./start.sh"
else
    echo ""
    echo " Falha na construção da imagem"
    exit 1
fi
