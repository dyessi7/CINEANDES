# 1. Red: VPC, subredes, NAT, tablas de rutas y grupos de seguridad
module "network" {
  source = "./modules/network"

  proyecto = var.proyecto
  entorno  = var.entorno
  vpc_cidr = var.vpc_cidr
  zonas    = var.zonas
}

# 2. Cómputo: las 8 Lambdas, conectadas a la red, a los datos y a la mensajería
module "compute" {
  source = "./modules/compute"

  # 2.1 Base del módulo
  proyecto = var.proyecto
  entorno  = var.entorno

  # 2.2 Desde network: dónde se ejecutan las funciones y con qué grupos de seguridad
  subredes_aplicacion_ids = module.network.subredes_aplicacion_ids
  sg_lambdas_id           = module.network.sg_lambdas_id
  sg_lambda_cartelera_id  = module.network.sg_lambda_cartelera_id

  # 2.3 Desde data: RDS Proxy (lectura y escritura, y solo lectura) y Redis
  rds_proxy_endpoint         = module.data.rds_proxy_endpoint
  rds_proxy_endpoint_lectura = module.data.rds_proxy_endpoint_lectura
  rds_proxy_arn              = module.data.rds_proxy_arn
  redis_endpoint             = module.data.redis_endpoint

  # 2.4 Desde messaging: las dos colas y la identidad de SES
  cola_ventas_arn   = module.messaging.cola_ventas_arn
  cola_ventas_url   = module.messaging.cola_ventas_url
  cola_avisos_arn   = module.messaging.cola_avisos_arn
  cola_avisos_url   = module.messaging.cola_avisos_url
  ses_identidad_arn = module.messaging.ses_identidad_arn
}

# 3. Datos: Aurora MySQL, RDS Proxy y ElastiCache Redis en las subredes de datos
module "data" {
  source = "./modules/data"

  # 3.1 Base del módulo
  proyecto = var.proyecto
  entorno  = var.entorno

  # 3.2 Desde network: subredes de datos y grupos de seguridad de cada componente
  subredes_datos_ids = module.network.subredes_datos_ids
  sg_aurora_id       = module.network.sg_aurora_id
  sg_rds_proxy_id    = module.network.sg_rds_proxy_id
  sg_redis_id        = module.network.sg_redis_id
  zonas              = var.zonas
}

# 4. Mensajería: colas SQS de ventas y avisos, e identidad de SES
module "messaging" {
  source = "./modules/messaging"

  proyecto = var.proyecto
  entorno  = var.entorno

  # Correo remitente
  correo_ses = var.correo_ses
}