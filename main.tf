# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# CDNU CLOUD AWS - GROUPE 5 : SERVICES MANAGÉS
# CONFIGURATION PRINCIPALE DE DÉPLOIEMENT
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# 1. RÉSEAU PAR DÉFAUT (Pour déploiement autonome de G5)
# Permet de récupérer les subnets et le groupe de sécurité par défaut de l'AWS Account
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_security_group" "default" {
  vpc_id = data.aws_vpc.default.id
  name   = "default"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Lot 1 : Stockage Objet S3 (11 Buckets par CDNU)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
module "storage" {
  source   = "./storage"
  for_each = { for k, v in var.cdnu_configs : k => v if v.deploy }

  project_name = var.project_name
  cdnu_name    = each.key

  tags = var.tags
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Lot 2 : Base de Données Relatioonelle RDS PostgreSQL
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
module "database" {
  source = "./database"

  project_name      = var.project_name
  instance_class    = var.db_instance_class
  allocated_storage = var.db_allocated_storage
  engine_version    = var.db_engine_version
  master_username   = var.db_master_username
  master_password   = var.db_password

  # Utilisation des subnets et du SG récupérés dynamiquement
  subnet_ids = data.aws_subnets.default.ids
  vpc_security_group_ids = [
    data.aws_security_group.default.id
  ]

  backup_retention_period = 7 # Rétention d'une semaine
  backup_window           = "03:00-04:00"
  multi_az                = var.multi_az
}
