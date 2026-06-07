module github.com/xrivate/capital-raising

go 1.21

require (
	// ==========================================
	// WEB FRAMEWORK
	// ==========================================
	github.com/gin-gonic/gin v1.9.1
	
	// ==========================================
	// gRPC
	// ==========================================
	google.golang.org/grpc v1.59.0
	google.golang.org/protobuf v1.31.0
	github.com/grpc-ecosystem/go-grpc-middleware v1.4.0
	
	// ==========================================
	// DATABASE
	// ==========================================
	github.com/lib/pq v1.10.9
	github.com/jackc/pgx/v5 v5.5.0
	github.com/cockroachdb/cockroach-go/v2 v2.3.6
	
	// ==========================================
	// CACHE
	// ==========================================
	github.com/redis/go-redis/v9 v9.3.0
	
	// ==========================================
	// KAFKA
	// ==========================================
	github.com/segmentio/kafka-go v0.4.47
	
	// ==========================================
	// ACTOR MODEL
	// ==========================================
	github.com/asynkron/protoactor-go v0.0.0-20230916100351-a3b85c66b8d5
	
	// ==========================================
	// UTILITÁRIOS
	// ==========================================
	github.com/google/uuid v1.4.0
	github.com/shopspring/decimal v1.3.1
	github.com/pkg/errors v0.9.1
	
	// ==========================================
	// VALIDAÇÃO
	// ==========================================
	github.com/go-playground/validator/v10 v10.16.0
	
	// ==========================================
	// CONFIGURAÇÃO
	// ==========================================
	github.com/spf13/viper v1.17.0
	
	// ==========================================
	// LOGGING E TRACING
	// ==========================================
	go.uber.org/zap v1.26.0
	go.opentelemetry.io/otel v1.21.0
	go.opentelemetry.io/otel/trace v1.21.0
	
	// ==========================================
	// SEGURANÇA
	// ==========================================
	github.com/golang-jwt/jwt/v5 v5.1.0
	golang.org/x/crypto v0.15.0
)
