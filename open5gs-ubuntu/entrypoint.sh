#!/bin/bash
# entrypoint.sh

set -e

# Função para aguardar serviço
wait_for_service() {
    local host=$1
    local port=$2
    local timeout=$3
    local start_time=$(date +%s)
    
    echo "Aguardando $host:$port..."
    
    while ! nc -z $host $port; do
        sleep 1
        local current_time=$(date +%s)
        local elapsed=$((current_time - start_time))
        
        if [ $elapsed -ge $timeout ]; then
            echo "Timeout aguardando $host:$port"
            exit 1
        fi
    done
    echo "$host:$port está disponível"
}

# Função para iniciar MongoDB
start_mongodb() {
    echo "Iniciando MongoDB..."
    mkdir -p /data/db
    mongod --fork --logpath /var/log/mongodb.log --bind_ip_all
    wait_for_service localhost 27017 30
}

# Função para configurar subscriber inicial
setup_subscriber() {
    echo "Configurando subscriber inicial..."
    
    cat > /tmp/setup-subscriber.js << EOF
db = db.getSiblingDB('open5gs');

if (db.subscribers.countDocuments({imsi: "001010123456780"}) === 0) {
    db.subscribers.insert({
        "imsi": "001010123456780",
        "security": {
            "k": "465B5CE8B199B49FAA5F0A2EE238A6BC",
            "opc": "E8ED289DEBA952E4283B54E88E6183CA",
            "amf": "8000",
            "op": null,
            "sqn": 0
        },
        "ambr": {
            "downlink": 1024000,
            "uplink": 1024000
        },
        "slice": [
            {
                "sst": 1,
                "default_indicator": true,
                "session": [
                    {
                        "name": "internet",
                        "type": 3,
                        "ambr": {
                            "downlink": 1024000,
                            "uplink": 1024000
                        },
                        "qos": {
                            "index": 9,
                            "arp": {
                                "priority_level": 8,
                                "pre_emption_capability": 1,
                                "pre_emption_vulnerability": 1
                            }
                        }
                    }
                ]
            }
        ]
    });
    print("Subscriber criado: IMSI=001010123456780");
} else {
    print("Subscriber já existe");
}
EOF
    
    mongo --host localhost:27017 /tmp/setup-subscriber.js
}

# Determinar qual serviço iniciar baseado no primeiro argumento
SERVICE=${1:-all}

case $SERVICE in
    mongodb)
        start_mongodb
        tail -f /var/log/mongodb.log
        ;;
    nrf)
        start_mongodb
        setup_subscriber
        echo "Iniciando NRF..."
        open5gs-nrfd -e /etc/open5gs/nrf.yaml
        ;;
    amf)
        wait_for_service open5gs-nrf 7777 60
        echo "Iniciando AMF..."
        open5gs-amfd -e /etc/open5gs/amf.yaml
        ;;
    smf)
        wait_for_service open5gs-nrf 7777 60
        echo "Iniciando SMF..."
        open5gs-smfd -e /etc/open5gs/smf.yaml
        ;;
    upf)
        wait_for_service open5gs-smf 8805 60
        echo "Iniciando UPF..."
        open5gs-upfd -e /etc/open5gs/upf.yaml
        ;;
    udm)
        wait_for_service open5gs-nrf 7777 60
        echo "Iniciando UDM..."
        open5gs-udmd -e /etc/open5gs/udm.yaml
        ;;
    udr)
        wait_for_service open5gs-nrf 7777 60
        echo "Iniciando UDR..."
        open5gs-udrd -e /etc/open5gs/udr.yaml
        ;;
    ausf)
        wait_for_service open5gs-nrf 7777 60
        echo "Iniciando AUSF..."
        open5gs-ausfd -e /etc/open5gs/ausf.yaml
        ;;
    pcf)
        wait_for_service open5gs-nrf 7777 60
        echo "Iniciando PCF..."
        open5gs-pcfd -e /etc/open5gs/pcf.yaml
        ;;
    all)
        echo "Modo desenvolvimento: Iniciando todos os serviços..."
        start_mongodb
        setup_subscriber
        
        # Iniciar NFs em background
        open5gs-nrfd -e /etc/open5gs/nrf.yaml &
        sleep 5
        
        open5gs-amfd -e /etc/open5gs/amf.yaml &
        open5gs-smfd -e /etc/open5gs/smf.yaml &
        open5gs-upfd -e /etc/open5gs/upf.yaml &
        open5gs-udmd -e /etc/open5gs/udm.yaml &
        open5gs-udrd -e /usr/local/etc/open5gs/udr.yaml &
        open5gs-ausfd -e /etc/open5gs/ausf.yaml &
        open5gs-pcfd -e /etc/open5gs/pcf.yaml &
        
        # Manter container rodando
        tail -f /dev/null
        ;;
    *)
        echo "Serviço desconhecido: $SERVICE"
        echo "Uso: $0 [mongodb|nrf|amf|smf|upf|udm|udr|ausf|pcf|all]"
        exit 1
        ;;
esac
