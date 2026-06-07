package core

import "errors"

// CircleHierarchy define o nível de acesso
var CircleHierarchy = map[string]int{
	"gold":      1,
	"black":     2,
	"sovereign": 3,
}

// CanAllocate verifica se o membro tem permissão para investir no veículo
func CanAllocate(memberCircle string, vehicleMinCircle string) bool {
	memberLevel, mOk := CircleHierarchy[memberCircle]
	vehicleLevel, vOk := CircleHierarchy[vehicleMinCircle]

	if !mOk || !vOk {
		return false
	}

	// Membro deve ter nível igual ou superior ao exigido pelo veículo
	return memberLevel >= vehicleLevel
}

// ValidateAllocationAmount verifica se o membro tem liquidez
func ValidateAllocationAmount(availableLiquidity float64, amount float64) error {
	if amount <= 0 {
		return errors.New("o valor da alocação deve ser maior que zero")
	}
	if amount > availableLiquidity {
		return errors.New("liquidez insuficiente para esta alocação")
	}
	return nil
}
