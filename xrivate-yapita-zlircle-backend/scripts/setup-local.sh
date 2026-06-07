#!/bin/bash
# ============================================
# SETUP LOCAL - XRIVATE YAPITA ZLIRCLE
# ============================================
# Configura ambiente de desenvolvimento local

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE} XrivateYapitaZlircle - Setup Local${NC}"
echo "========================================"

# ==========================================
# VERIFICA DEPENDÊNCIAS
# ==========================================
echo -e "${YELLOW} Verificando dependências...${NC}"

check_command() {
    if ! command -v $1 &> /dev/null; then
        echo -e "${RED} $1 não encontrado. Por favor, instale: $2${NC}"
        exit 1
    else
        echo -e "${GREEN} $1 encontrado${NC}"
    fi
}

check_command "docker" "https://docs.docker.com/get-docker/"
check_command "docker-compose" "https://docs.docker.com/compose/install/"
check_command "kubectl" "https://kubernetes.io/docs/tasks/tools/"
check_command "rustc" "https://rustup.rs/"
check_command "go" "https://go.dev/dl/"
check_command "java" "https://adoptium.net/"

# ==========================================
# VERIFICA VERSÕES
# ==========================================
echo -e "${YELLOW}🔍 Verificando versões...${NC}"

RUST_VERSION=$(rustc --version | cut -d' ' -f2)
GO_VERSION=$(go version | cut -d' ' -f3 | sed 's/go//')
JAVA_VERSION=$(java -version 2>&1 | head -n1 | cut -d'"' -f2 | cut -d'.' -f1)

echo -e "${GREEN}Rust: $RUST_VERSION${NC}"
echo -e "${GREEN}Go: $GO_VERSION${NC}"
echo -e "${GREEN}Java: $JAVA_VERSION${NC}"

# ==========================================
# CONFIGURA VARIÁVEIS DE AMBIENTE
# ==========================================
echo -e "${YELLOW}⚙️  Configurando variáveis de ambiente...${NC}"

if [ ! -f .env.local ]; then
    cp .env.example .env.local
    echo -e "${GREEN}✅ Arquivo .env.local criado${NC}"
else
    echo -e "${YELLOW}⚠️  Arquivo .env.local já existe${NC}"
fi

# ==========================================
# INICIA INFRAESTRUTURA
# ==========================================
echo -e "${YELLOW} Iniciando infraestrutura...${NC}"

docker-compose -f docker-compose.infra.yml up -d

echo -e "${GREEN} Infraestrutura iniciada${NC}"
echo ""
echo "Serviços disponíveis:"
echo "  - Kafka: localhost:9092"
echo "  - CockroachDB: localhost:26257 (UI: localhost:8081)"
echo "  - TimescaleDB: localhost:5433"
echo "  - ClickHouse: localhost:8123"
echo "  - Neo4j: localhost:7474 (Browser)"
echo "  - Redis: localhost:6379"
echo "  - MinIO: localhost:9001 (Console)"
echo "  - Vault: localhost:8200"
echo "  - Temporal: localhost:8080 (UI)"
echo "  - Prometheus: localhost:9090"
echo "  - Grafana: localhost:3001"
echo "  - Jaeger: localhost:16686"

# ==========================================
# AGUARDA SERVIÇOS FICAREM PRONTOS
# ==========================================
echo -e "${YELLOW}⏳ Aguardando serviços ficarem prontos...${NC}"

wait_for_service() {
    local name=$1
    local url=$2
    local max_attempts=30
    local attempt=1

    while [ $attempt -le $max_attempts ]; do
        if curl -s -f $url > /dev/null 2>&1; then
            echo -e "${GREEN} $name pronto${NC}"
            return 0
        fi
        echo -e "${YELLOW} Aguardando $name... ($attempt/$max_attempts)${NC}"
        sleep 2
        attempt=$((attempt + 1))
    done

    echo -e "${RED} $name não ficou pronto${NC}"
    return 1
}

wait_for_service "CockroachDB" "http://localhost:8081/health"
wait_for_service "Temporal" "http://localhost:8080"
wait_for_service "Grafana" "http://localhost:3001/api/health"

# ==========================================
# RODA MIGRATIONS
# ==========================================
echo -e "${YELLOW} Executando migrations...${NC}"

./scripts/db-migrate.sh

echo -e "${GREEN} Migrations executadas${NC}"

# ==========================================
# COMPILA SERVIÇOS
# ==========================================
echo -e "${YELLOW}🏗️ Compilando serviços...${NC}"

echo -e "${BLUE} Compilando Vehicle Factory (Rust)...${NC}"
cd services/vehicle-factory && cargo build && cd ../..

echo -e "${BLUE} Compilando Capital Raising (Go)...${NC}"
cd services/capital-raising && go build ./... && cd ../..

echo -e "${BLUE} Compilando Special Operations (Java)...${NC}"
cd services/special-operations && ./gradlew build -x test && cd ../..

echo -e "${BLUE} Compilando Atomic Settlement (Rust)...${NC}"
cd services/atomic-settlement && cargo build && cd ../..

echo -e "${GREEN} Todos os serviços compilados${NC}"

# ==========================================
# FINALIZAÇÃO
# ==========================================
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN} SETUP LOCAL CONCLUÍDO COM SUCESSO!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${BLUE}Próximos passos:${NC}"
echo "  1. Iniciar serviços: make start-services"
echo "  2. Acessar dashboard: http://localhost:3000"
echo "  3. Acessar GraphQL: http://localhost:4000/graphql"
echo "  4. Monitorar: http://localhost:3001 (Grafana)"
echo ""
echo -e "${YELLOW}Para parar tudo: docker-compose -f docker-compose.infra.yml down${NC}"
