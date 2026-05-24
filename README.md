# G5 - Services Managés

## 📋 Objectifs
- Buckets S3 (1 par CDNU)
- Base de données PostgreSQL managée
- Registre de conteneurs ECR
- Politiques de sauvegarde

## 📁 Contenu
- `storage/` - Module S3 avec lifecycle policies
- `database/` - Module RDS PostgreSQL + backup
- `ecr.tf` - Registre de conteneurs pour l'API

## ✅ Livrables
- ✅ 11 buckets S3 avec lifecycle (GLACIER_IR → GLACIER → DEEP_ARCHIVE)
- ✅ RDS PostgreSQL 15 (db.t3.micro, 20 GB)
- ✅ AWS Backup pour RDS (retention 1 jour)
- ✅ ECR pour images Docker de l'API
# CDNU--G5-Services-manag-s
