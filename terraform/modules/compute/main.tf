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