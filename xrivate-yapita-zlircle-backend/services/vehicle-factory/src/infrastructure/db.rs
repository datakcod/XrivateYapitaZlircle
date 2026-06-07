use sqlx::postgres::PgPoolOptions;
use sqlx::PgPool;
use std::env;

pub async fn init_db() -> Result<PgPool, sqlx::Error> {
    let database_url = env::var("DATABASE_URL")
        .expect("DATABASE_URL must be set in .env");

    let pool = PgPoolOptions::new()
        .max_connections(20)
        .connect(&database_url)
        .await?;

    println!("Database pool connected successfully");
    Ok(pool)
}

// Exemplo de função para salvar veículo (usar nos handlers)
/*
pub async fn save_vehicle(pool: &PgPool, vehicle: &Vehicle) -> Result<(), sqlx::Error> {
    sqlx::query!(
        "INSERT INTO vehicles (id, name, type, min_circle_tier, total_capacity, expected_yield) 
         VALUES ($1, $2, $3, $4, $5, $6)",
        vehicle.id, vehicle.name, vehicle.vehicle_type, 
        vehicle.min_circle_tier, vehicle.total_capacity, vehicle.expected_yield
    )
    .execute(pool)
    .await?;
    Ok(())
}
*/
