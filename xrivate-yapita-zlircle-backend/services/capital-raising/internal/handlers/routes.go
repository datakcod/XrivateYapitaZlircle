package handlers

import (
	"net/http"
	"github.com/gin-gonic/gin"
	"github.com/xrivate/capital-raising/internal/core"
)

type AllocateRequest struct {
	MemberID string  `json:"member_id" binding:"required"`
	VehicleID string `json:"vehicle_id" binding:"required"`
	Amount   float64 `json:"amount" binding:"required"`
	Circle   string  `json:"circle" binding:"required"`
}

// SetupRoutes configura as rotas do Gin
func SetupRoutes(router *gin.Engine) {
	v1 := router.Group("/api/v1")
	{
		v1.POST("/allocate", HandleAllocate)
		v1.GET("/vehicles", HandleGetVehicles)
	}
}

// HandleAllocate processa a alocação de capital
func HandleAllocate(c *gin.Context) {
	var req AllocateRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Validação de Círculo (Matching)
	// No MVP, buscaríamos o vehicleMinCircle no banco. Aqui hardcode para exemplo.
	vehicleMinCircle := "black" 
	
	if !core.CanAllocate(req.Circle, vehicleMinCircle) {
		c.JSON(http.StatusForbidden, gin.H{"error": "Seu círculo não permite acesso a este veículo"})
		return
	}

	// Se passou, salva no banco (implementar db call aqui)
	c.JSON(http.StatusCreated, gin.H{
		"success": true,
		"message": "Alocação realizada com sucesso",
		"data":    req,
	})
}

func HandleGetVehicles(c *gin.Context) {
	// Retornar lista de veículos do banco
	c.JSON(http.StatusOK, gin.H{"data": []interface{}{}})
}
