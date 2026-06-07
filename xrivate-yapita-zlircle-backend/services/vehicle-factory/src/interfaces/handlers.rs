use actix_web::{web, HttpResponse};
use crate::domain::vehicle::{Vehicle, CreateVehicleRequest};

// POST /api/v1/vehicles
pub async fn create_vehicle(
    body: web::Json<CreateVehicleRequest>,
) -> HttpResponse {
    // No MVP real, isso salvaria no banco via db.rs
    let new_vehicle = Vehicle::new(body.into_inner());
    
    HttpResponse::Created().json(serde_json::json!({
        "success": true,
        "data": new_vehicle
    }))
}

// GET /api/v1/vehicles
pub async fn list_vehicles() -> HttpResponse {
    // No MVP real, isso faria um SELECT no banco
    let mock_vehicles = vec![
        serde_json::json!({
            "id": "123e4567-e89b-12d3-a456-426614174000",
            "name": "FII Xrivate Prime",
            "vehicle_type": "FII",
            "min_circle_tier": "gold",
            "total_capacity": 50000000.00,
            "allocated_capacity": 12500000.00,
            "expected_yield": 11.50,
            "status": "open"
        })
    ];

    HttpResponse::Ok().json(serde_json::json!({
        "success": true,
        "data": mock_vehicles
    }))
}
