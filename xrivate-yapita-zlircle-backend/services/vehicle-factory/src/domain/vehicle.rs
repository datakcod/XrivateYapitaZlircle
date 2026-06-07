use serde::{Deserialize, Serialize};
use uuid::Uuid;
use chrono::{DateTime, Utc};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Vehicle {
    pub id: Uuid,
    pub name: String,
    pub vehicle_type: String, // FII, FIDC, SPV
    pub min_circle_tier: String, // gold, black, sovereign
    pub total_capacity: f64,
    pub allocated_capacity: f64,
    pub expected_yield: f64,
    pub status: String,
    pub created_at: DateTime<Utc>,
}

#[derive(Debug, Deserialize)]
pub struct CreateVehicleRequest {
    pub name: String,
    pub vehicle_type: String,
    pub min_circle_tier: String,
    pub total_capacity: f64,
    pub expected_yield: f64,
}

impl Vehicle {
    pub fn new(req: CreateVehicleRequest) -> Self {
        Self {
            id: Uuid::new_v4(),
            name: req.name,
            vehicle_type: req.vehicle_type,
            min_circle_tier: req.min_circle_tier,
            total_capacity: req.total_capacity,
            allocated_capacity: 0.0,
            expected_yield: req.expected_yield,
            status: "open".to_string(),
            created_at: Utc::now(),
        }
    }
}
