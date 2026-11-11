# 1. Prefijo de nombres
locals {
  prefijo = "${var.proyecto}-${var.entorno}"
}

# 2. Funciones del sistema: una por responsabilidad
locals {
  funciones = {
    confirmar_venta     = { grupo = "general", tiempo_max = 30, memoria = 256 }
    registrar_venta     = { grupo = "general", tiempo_max = 30, memoria = 256 }
    bloquear_butaca     = { grupo = "general", tiempo_max = 10, memoria = 256 }
    liberar_bloqueos    = { grupo = "general", tiempo_max = 60, memoria = 256 }
    reportes            = { grupo = "general", tiempo_max = 60, memoria = 512 }
    consultar_mapa      = { grupo = "general", tiempo_max = 10, memoria = 256 }
    consultar_cartelera = { grupo = "cartelera", tiempo_max = 10, memoria = 256 }
    notificar           = { grupo = null, tiempo_max = 30, memoria = 128 }
  }

  grupos_seguridad = {
    general   = var.sg_lambdas_id
    cartelera = var.sg_lambda_cartelera_id
  }
}

# 3. ROLES DE IAM: uno por función, para que cada una tenga solo sus permisos
# 3.1 Rol: solo el servicio de Lambda puede usarlo
resource "aws_iam_role" "funcion" {
  for_each = local.funciones

  name = "${local.prefijo}-${replace(each.key, "_", "-")}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

# 3.2 Permisos básicos: escribir registros y, si va en la VPC, conectarse a ella
resource "aws_iam_role_policy_attachment" "basico" {
  for_each = local.funciones

  role = aws_iam_role.funcion[each.key].name
  policy_arn = (
    each.value.grupo == null
    ? "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
    : "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
  )
}