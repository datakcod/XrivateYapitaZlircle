// ============================================
// VEHICLE FACTORY - ENTRY POINT
// ============================================
// Serviço principal para montagem de veículos financeiros

use actix_web::{web, App, HttpServer, middleware};
use tracing_actix_web::TracingLogger;
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};

mod domain;
mod application;
mod infrastructure;
mod interfaces;

use infrastructure::{
    config::AppConfig,
    database::DatabasePool,
    kafka::KafkaProducer,
    redis::RedisClient,
};

#[tokio::main]
async fn main() -> std::io::Result<()> {
    // ==========================================
    // INICIALIZAÇÃO DE TRACING
    // ==========================================
    tracing_subscriber::registry()
        .with(tracing_subscriber::EnvFilter::new(
            std::env::var("RUST_LOG").unwrap_or_else(|_| "info,tower_http=debug".into()),
        ))
        .with(tracing_subscriber::fmt::layer().json())
        .init();

    tracing::info!("Iniciando Vehicle Factory...");

    // ==========================================
    // CARREGA CONFIGURAÇÃO
    // ==========================================
    let config = AppConfig::load().expect("Falha ao carregar configuração");
    tracing::info!("Configuração carregada: env={}", config.environment);

    // ==========================================
    // INICIALIZA DEPENDÊNCIAS
    // ==========================================
    
    // Database Pool (CockroachDB/TimescaleDB)
    let db_pool = DatabasePool::new(&config.database_url)
        .await
        .expect("Falha ao conectar ao banco de dados");
    tracing::info!("Database pool inicializado");

    // Redis Client
    let redis_client = RedisClient::new(&config.redis_url)
        .await
        .expect("Falha ao conectar ao Redis");
    tracing::info!("Redis client inicializado");

    // Kafka Producer
    let kafka_producer = KafkaProducer::new(&config.kafka_brokers)
        .expect("Falha ao inicializar Kafka producer");
    tracing::info!("Kafka producer inicializado");

    // ==========================================
    // RUN MIGRATIONS
    // ==========================================
    sqlx::migrate!("./migrations")
        .run(&db_pool)
        .await
        .expect("Falha ao executar migrations");
    tracing::info!("Migrations executadas");

    // ==========================================
    // INJECT DEPENDENCIES
    // ==========================================
    let app_state = web::Data::new(interfaces::AppState {
        db: db_pool,
        redis: redis_client,
        kafka: kafka_producer,
        config: config.clone(),
    });

    // ==========================================
    // START HTTP SERVER
    // ==========================================
    let bind_address = format!("{}:{}", config.host, config.port);
    tracing::info!("Servidor HTTP iniciando em {}", bind_address);

    HttpServer::new(move || {
        App::new()
            .wrap(TracingLogger::default())
            .wrap(middleware::Compress::default())
            .wrap(middleware::Logger::default())
            .app_data(app_state.clone())
            .app_data(web::JsonConfig::default().limit(4096))
            // Health check
            .route("/health", web::get().to(interfaces::handlers::health::health_check))
            .route("/ready", web::get().to(interfaces::handlers::health::readiness_check))
            // Vehicle endpoints
            .service(
                web::scope("/api/v1/vehicles")
                    .route("", web::post().to(interfaces::handlers::vehicles::create_vehicle))
                    .route("/{id}", web::get().to(interfaces::handlers::vehicles::get_vehicle))
                    .route("/{id}/tokens", web::post().to(interfaces::handlers::vehicles::issue_tokens))
                    .route("", web::get().to(interfaces::handlers::vehicles::list_vehicles))
            )
            // SPV endpoints
            .service(
                web::scope("/api/v1/spvs")
                    .route("", web::post().to(interfaces::handlers::spvs::create_spv))
                    .route("/{id}", web::get().to(interfaces::handlers::spvs::get_spv))
            )
    })
    .bind(&bind_address)?
    .workers(num_cpus::get())
    .run()
    .await
}
