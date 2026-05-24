# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# VARIABLES - MODULE STORAGE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

variable "project_name" {
  description = "Nom du projet"
  type        = string
}

variable "cdnu_name" {
  description = "Nom du CDNU (ex: yaounde, douala)"
  type        = string
}

variable "cors_allowed_origins" {
  description = "Origines autorisées pour CORS"
  type        = list(string)
  default     = ["*"] # À restreindre en production
}

variable "enable_replication" {
  description = "Activer la réplication cross-region"
  type        = bool
  default     = false
}

variable "replication_destination_bucket_arn" {
  description = "ARN du bucket de destination pour réplication"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags additionnels"
  type        = map(string)
  default     = {}
}
