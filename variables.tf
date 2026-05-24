# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# VARIABLES GLOBALES - SERVICES MANAGÉS (G5)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

variable "aws_region" {
  description = "Région AWS par défaut"
  type        = string
  default     = "eu-central-1"
}

variable "project_name" {
  description = "Nom unique du projet"
  type        = string
  default     = "cdnu-cloud-g5"
}

variable "tags" {
  description = "Tags à appliquer aux ressources"
  type        = map(string)
  default = {
    Project     = "CDNU-Cloud-G5"
    ManagedBy   = "Terraform"
    Team        = "Groupe-5"
    Environment = "production"
  }
}

variable "cdnu_configs" {
  description = "Configuration des CDNUs"
  type = map(object({
    vpc_cidr      = string
    instance_type = string
    az            = string
    region        = string
    deploy        = bool
  }))
}

# Configuration RDS Database
variable "db_instance_class" {
  description = "Instance class pour RDS PostgreSQL"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "Storage alloué en Go"
  type        = number
  default     = 20
}

variable "db_engine_version" {
  description = "Version du moteur PostgreSQL"
  type        = string
  default     = "15.18"
}

variable "db_master_username" {
  description = "Nom d'utilisateur administrateur de la BDD"
  type        = string
  default     = "cdnu_admin"
}

variable "db_password" {
  description = "Mot de passe administrateur de la BDD"
  type        = string
  sensitive   = true
}

variable "multi_az" {
  description = "Activer le déploiement Multi-AZ pour RDS"
  type        = bool
  default     = false
}
