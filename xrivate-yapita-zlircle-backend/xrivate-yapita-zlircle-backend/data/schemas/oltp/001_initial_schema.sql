-- ==========================================
-- XRIVATE YAPITA ZLIRCLE - INITIAL SCHEMA
-- ==========================================

-- 1. MEMBROS E CÍRCULOS
CREATE TABLE IF NOT EXISTS members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    circle_tier VARCHAR(50) NOT NULL CHECK (circle_tier IN ('gold', 'black', 'sovereign')),
    patrimony DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    status VARCHAR(50) NOT NULL DEFAULT 'active',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 2. VEÍCULOS FINANCEIROS (SPVs, Fundos)
CREATE TABLE IF NOT EXISTS vehicles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    type VARCHAR(50) NOT NULL, -- ex: 'FII', 'FIDC', 'SPV_Infra'
    min_circle_tier VARCHAR(50) NOT NULL DEFAULT 'gold',
    total_capacity DECIMAL(18,2) NOT NULL,
    allocated_capacity DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    expected_yield DECIMAL(5,2) NOT NULL, -- ex: 12.50 (para 12.50%)
    status VARCHAR(50) NOT NULL DEFAULT 'open',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 3. ALOCAÇÕES (Investimento do Membro no Veículo)
CREATE TABLE IF NOT EXISTS allocations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    member_id UUID NOT NULL REFERENCES members(id),
    vehicle_id UUID NOT NULL REFERENCES vehicles(id),
    amount DECIMAL(18,2) NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'confirmed',
    allocated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(member_id, vehicle_id)
);

-- 4. LEDGER / TRANSAÇÕES (Extrato Financeiro)
CREATE TABLE IF NOT EXISTS transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    member_id UUID NOT NULL REFERENCES members(id),
    type VARCHAR(50) NOT NULL, -- 'deposit', 'withdrawal', 'yield_distribution', 'revenue_share'
    amount DECIMAL(18,2) NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Índices para performance
CREATE INDEX idx_members_circle ON members(circle_tier);
CREATE INDEX idx_vehicles_status ON vehicles(status);
CREATE INDEX idx_allocations_member ON allocations(member_id);
CREATE INDEX idx_transactions_member ON transactions(member_id);
