# 1. Prefijo de nombres
locals {
  prefijo = "${var.proyecto}-${var.entorno}"

  # Grupos de usuarios de Cognito y para qué sirve cada uno
  grupos_cognito = {
    clientes       = "Clientes de la web y la app móvil"
    cajeros        = "Cajeros de las sedes"
    administracion = "Administración: reportes y auditoría"
  }
}

# 2. COGNITO: inicio de sesión de clientes, cajeros y administración
# 2.1 Grupo de usuarios: inicio de sesión por correo
resource "aws_cognito_user_pool" "principal" {
  name = "${local.prefijo}-usuarios"

  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]

  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_uppercase = true
    require_numbers   = true
    require_symbols   = false
  }

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  # En desarrollo debe poder destruirse con el pipeline
  deletion_protection = "INACTIVE"
}

# 2.2 Cliente de aplicación: lo usan la web, la app y las cajas
# Sin secreto: son clientes públicos que no pueden guardarlo
resource "aws_cognito_user_pool_client" "web" {
  name         = "${local.prefijo}-cliente"
  user_pool_id = aws_cognito_user_pool.principal.id

  generate_secret = false

  explicit_auth_flows = [
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
  ]

  # No revelar si un correo existe o no al fallar el inicio de sesión
  prevent_user_existence_errors = "ENABLED"
  enable_token_revocation       = true

  access_token_validity  = 60
  id_token_validity      = 60
  refresh_token_validity = 30

  token_validity_units {
    access_token  = "minutes"
    id_token      = "minutes"
    refresh_token = "days"
  }
}

# 2.3 Grupos: clientes, cajeros y administración
resource "aws_cognito_user_group" "grupo" {
  for_each = local.grupos_cognito

  name         = each.key
  description  = each.value
  user_pool_id = aws_cognito_user_pool.principal.id
}
