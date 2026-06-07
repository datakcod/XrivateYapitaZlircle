# ============================================
# VEHICLE FACTORY - MULTI-STAGE BUILD
# ============================================
# Build otimizado com Distroless para produção

# ==========================================
# STAGE 1: BUILDER
# ==========================================
FROM rust:1.73-slim-bookworm AS builder

WORKDIR /app

# Instala dependências de sistema
RUN apt-get update && apt-get install -y \
    pkg-config \
    libssl-dev \
    cmake \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Copia manifests primeiro (cache de dependências)
COPY Cargo.toml Cargo.lock ./
RUN mkdir src && echo "fn main() {}" > src/main.rs
RUN cargo build --release
RUN rm -rf src

# Copia código fonte
COPY . .

# Toca o main.rs para forçar rebuild
RUN touch src/main.rs

# Build final
RUN cargo build --release

# ==========================================
# STAGE 2: RUNTIME (Distroless)
# ==========================================
FROM gcr.io/distroless/cc-debian12:nonroot

WORKDIR /app

# Copia binário compilado
COPY --from=builder /app/target/release/vehicle-factory /app/vehicle-factory

# Copia migrations
COPY --from=builder /app/migrations /app/migrations

# Copia configurações
COPY --from=builder /app/config /app/config

# Variáveis de ambiente
ENV RUST_LOG=info \
    RUST_BACKTRACE=1 \
    APP_ENV=production

# Expõe porta
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD ["/app/vehicle-factory", "--health-check"]

# Usuário não-root
USER nonroot:nonroot

# Entry point
ENTRYPOINT ["/app/vehicle-factory"]
