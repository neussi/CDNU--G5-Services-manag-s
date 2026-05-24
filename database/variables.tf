variable "project_name" {
  description = "Nom du projet"
  type        = string
}

variable "instance_class" {
  description = "Classe d'instance RDS"
  type        = string
}

variable "allocated_storage" {
  description = "Stockage alloué en GB"
  type        = number
}

variable "engine_version" {
  description = "Version PostgreSQL"
  type        = string
}

variable "master_username" {
  description = "Nom d'utilisateur master"
  type        = string
}

variable "master_password" {
  description = "Mot de passe master"
  type        = string
  sensitive   = true
}

variable "subnet_ids" {
  description = "IDs des subnets pour le subnet group"
  type        = list(string)
}

variable "vpc_security_group_ids" {
  description = "IDs des security groups"
  type        = list(string)
}

variable "backup_retention_period" {
  description = "Période de rétention des backups (jours)"
  type        = number
}

variable "backup_window" {
  description = "Fenêtre de backup (format HH:MM-HH:MM)"
  type        = string
}

variable "multi_az" {
  description = "Enable Multi-AZ deployment"
  type        = bool
  default     = false
}