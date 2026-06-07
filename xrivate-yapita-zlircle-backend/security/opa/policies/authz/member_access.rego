# ============================================
# OPA POLICY - MEMBER ACCESS CONTROL
# ============================================
# Controla acesso de membros às operações da plataforma

package xrivate.authz.member

import future.keywords.if
import future.keywords.in

# ==========================================
# DEFAULT DENY
# ==========================================
default allow := false

# ==========================================
# MEMBERSHIP VALIDATION
# ==========================================

# Permite acesso se o usuário é membro ativo (liquidez ativa)
allow if {
    input.user.authenticated == true
    input.user.member_status == "active"
    input.user.circle in {"gold", "black", "sovereign"}
}

# ==========================================
# CIRCLE-BASED ACCESS CONTROL
# ==========================================

# Circle Gold: Acesso básico ao dashboard
allow if {
    input.action == "dashboard:view"
    input.user.circle == "gold"
    input.user.patrimony >= 10000000  # R$ 10M
}

# Circle Black: Acesso a operações especiais
allow if {
    input.action in {"operations:view", "operations:invest"}
    input.user.circle in {"black", "sovereign"}
    input.user.patrimony >= 50000000  # R$ 50M
}

# Circle Sovereign: Acesso total + governança
allow if {
    input.action in {
        "governance:view",
        "governance:vote",
        "committees:access",
        "audit:logs"
    }
    input.user.circle == "sovereign"
    input.user.patrimony >= 100000000  # R$ +100M
}

# ==========================================
# OPERAÇÃO ESPECÍFICA: LIQUIDEZ
# ==========================================

# Membros podem solicitar resgate apenas em janelas permitidas
allow if {
    input.action == "liquidity:request_redemption"
    input.user.member_status == "active"
    is_redemption_window_open(input.timestamp)
    input.amount <= input.user.available_liquidity
}

# ==========================================
# MERCADO SECUNDÁRIO
# ==========================================

# Permite negociação no mercado secundário
allow if {
    input.action == "secondary_market:trade"
    input.user.circle in {"black", "sovereign"}
    input.user.kyc_verified == true
    input.user.aml_cleared == true
}

# ==========================================
# AUXILIARY FUNCTIONS
# ==========================================

# Verifica se está em janela de resgate
is_redemption_window_open(timestamp) if {
    # Janelas trimestrais (última semana do trimestre)
    time.clock(timestamp)[0] >= 22  # Outubro, Novembro, Dezembro
}

is_redemption_window_open(timestamp) if {
    # Janelas semestrais (junho e dezembro)
    time.clock(timestamp)[0] in {6, 12}
}

# ==========================================
# AUDIT LOG
# ==========================================

# Registra todas as decisões para auditoria
audit_log := {
    "timestamp": time.now_ns(),
    "user_id": input.user.id,
    "action": input.action,
    "decision": allow,
    "circle": input.user.circle,
    "resource": input.resource,
}
