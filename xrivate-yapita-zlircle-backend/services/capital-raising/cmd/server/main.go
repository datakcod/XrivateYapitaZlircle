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

// ============================================
// CAPITAL RAISING - ENTRY POINT
// ============================================
// Serviço Go para captações e matching de investidores

package main

import (
	"context"
	"fmt"
	"net"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/xrivate/capital-raising/internal/compliance"
	"github.com/xrivate/capital-raising/internal/config"
	"github.com/xrivate/capital-raising/internal/core"
	"github.com/xrivate/capital-raising/internal/matching"
	"github.com/xrivate/capital-raising/internal/persistence"
	"github.com/xrivate/capital-raising/pkg/logger"
	"go.uber.org/zap"
)

func main() {
	// ==========================================
	// INICIALIZA LOGGER
	// ==========================================
	log, _ := logger.New()
	defer log.Sync()
	log.Info("Iniciando Capital Raising Service...")

	// ==========================================
	// CARREGA CONFIGURAÇÃO
	// ==========================================
	cfg, err := config.Load()
	if err != nil {
		log.Fatal("Falha ao carregar configuração", zap.Error(err))
	}
	log.Info("Configuração carregada", zap.String("env", cfg.Environment))

	// ==========================================
	// INICIALIZA DEPENDÊNCIAS
	// ==========================================
	
	// Database
	db, err := persistence.NewCockroachDB(cfg.DatabaseURL)
	if err != nil {
		log.Fatal("Falha ao conectar ao banco", zap.Error(err))
	}
	defer db.Close()
	log.Info("Database conectado")

	// Redis
	redisClient, err := persistence.NewRedis(cfg.RedisURL)
	if err != nil {
		log.Fatal("Falha ao conectar ao Redis", zap.Error(err))
	}
	defer redisClient.Close()
	log.Info("Redis conectado")

	// Kafka
	kafkaProducer, err := core.NewKafkaProducer(cfg.KafkaBrokers)
	if err != nil {
		log.Fatal("Falha ao inicializar Kafka", zap.Error(err))
	}
	defer kafkaProducer.Close()
	log.Info("Kafka producer inicializado")

	// Actor System (Proto.Actor)
	actorSystem := core.NewActorSystem()
	log.Info("Actor System inicializado")

	// ==========================================
	// INICIALIZA SERVIÇOS DE DOMÍNIO
	// ==========================================
	
	// Compliance (KYC/AML)
	complianceService := compliance.NewService(cfg.ComplianceAPIKey)
	log.Info("Compliance Service inicializado")

	// Matching Engine
	matchingEngine := matching.NewEngine(db, redisClient, actorSystem)
	log.Info("Matching Engine inicializado")

	// ==========================================
	// CONFIGURA GIN
	// ==========================================
	if cfg.Environment == "production" {
		gin.SetMode(gin.ReleaseMode)
	}

	router := gin.New()
	router.Use(gin.Recovery())
	router.Use(logger.GinMiddleware(log))
	router.Use(core.CORSMiddleware(cfg.AllowedOrigins))

	// ==========================================
	// REGISTRA ROTAS
	// ==========================================
	
	// Health checks
	router.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"status": "healthy"})
	})
	router.GET("/ready", func(c *gin.Context) {
		if err := db.Ping(); err != nil {
			c.JSON(http.StatusServiceUnavailable, gin.H{"status": "unhealthy"})
			return
		}
		c.JSON(http.StatusOK, gin.H{"status": "ready"})
	})

	// API v1
	v1 := router.Group("/api/v1")
	{
		// Capital Raising
		capital := v1.Group("/capital")
		{
			capital.POST("/rounds", matchingEngine.CreateCapitalRound)
			capital.GET("/rounds/:id", matchingEngine.GetCapitalRound)
			capital.POST("/rounds/:id/invest", matchingEngine.InvestInRound)
			capital.GET("/rounds/:id/book", matchingEngine.GetBookBuilding)
		}

		// Matching
		match := v1.Group("/matching")
		{
			match.POST("/opportunities", matchingEngine.RegisterOpportunity)
			match.POST("/investors", matchingEngine.RegisterInvestor)
			match.POST("/execute", matchingEngine.ExecuteMatch)
		}

		// Compliance
		comp := v1.Group("/compliance")
		{
			comp.POST("/kyc", complianceService.SubmitKYC)
			comp.POST("/aml", complianceService.SubmitAML)
			comp.GET("/status/:id", complianceService.GetStatus)
		}
	}

	// ==========================================
	// START HTTP SERVER
	// ==========================================
	srv := &http.Server{
		Addr:         fmt.Sprintf(":%d", cfg.Port),
		Handler:      router,
		ReadTimeout:  15 * time.Second,
		WriteTimeout: 15 * time.Second,
		IdleTimeout:  60 * time.Second,
	}

	// Inicia servidor em goroutine
	go func() {
		log.Info("Servidor HTTP iniciando", zap.Int("port", cfg.Port))
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatal("Falha ao iniciar servidor", zap.Error(err))
		}
	}()

	// ==========================================
	// GRACEFUL SHUTDOWN
	// ==========================================
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	log.Info("Shutting down server...")

	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	if err := srv.Shutdown(ctx); err != nil {
		log.Fatal("Server forced to shutdown", zap.Error(err))
	}

	log.Info("Server exited gracefully")
}
