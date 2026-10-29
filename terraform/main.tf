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
  vpc_id                  = module.network.vpc_id
  vpc_cidr                = module.network.vpc_cidr
  subredes_aplicacion_ids = module.network.subredes_aplicacion_ids
}