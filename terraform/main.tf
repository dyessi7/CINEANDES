module "network" {
  source = "./modules/network"

  proyecto = var.proyecto
  entorno  = var.entorno
  vpc_cidr = var.vpc_cidr
  zonas    = var.zonas
}

module "compute" {
  source = "./modules/compute"

  proyecto                = var.proyecto
  entorno                 = var.entorno
  subredes_aplicacion_ids = module.network.subredes_aplicacion_ids
  sg_lambdas_id           = module.network.sg_lambdas_id
  sg_lambda_cartelera_id  = module.network.sg_lambda_cartelera_id
}

module "data" {
  source = "./modules/data"

  proyecto           = var.proyecto
  entorno            = var.entorno
  subredes_datos_ids = module.network.subredes_datos_ids
  sg_aurora_id       = module.network.sg_aurora_id
  sg_rds_proxy_id    = module.network.sg_rds_proxy_id
  sg_redis_id        = module.network.sg_redis_id
  zonas              = var.zonas
}

module "messaging" {
  source = "./modules/messaging"

  proyecto   = var.proyecto
  entorno    = var.entorno
  correo_ses = var.correo_ses
}