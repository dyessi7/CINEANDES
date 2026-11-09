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