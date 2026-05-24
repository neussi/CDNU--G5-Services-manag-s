# Module Storage (G5)

Module Terraform pour la gestion du stockage S3 des CDNU.

## Fonctionnalités

- ✅ Bucket S3 par CDNU avec naming unique
- ✅ Versioning activé
- ✅ Encryption AES-256
- ✅ Block Public Access (sécurité)
- ✅ Logging dans bucket séparé
- ✅ CORS pour accès API
- ✅ Bucket Policy (HTTPS uniquement)
- ✅ Intelligent-Tiering automatique
- ✅ CloudWatch metrics

## Lifecycle Policies (Optimisation Coûts)

Le stockage S3 représente ~70% des coûts. Les lifecycle policies réduisent drastiquement les coûts :

### Règle 1: Transition vers Glacier
- **30 jours** : Standard → Glacier Instant Retrieval
- **90 jours** : Glacier IR → Glacier Flexible Retrieval
- **180 jours** : Glacier → Deep Archive

### Règle 2: Anciennes versions
- **30 jours** : Versions non-courantes → Glacier
- **90 jours** : Suppression versions non-courantes

### Règle 3: Nettoyage uploads incomplets
- **7 jours** : Suppression uploads multipart incomplets

### Règle 4: Fichiers temporaires
- **7 jours** : Suppression fichiers `temp/`

### Règle 5: Logs
- **30 jours** : Standard → Standard-IA
- **90 jours** : Standard-IA → Glacier
- **365 jours** : Suppression

## Réduction des Coûts

| Storage Class | Coût relatif | Usage |
|---------------|--------------|-------|
| Standard | 100% | Fichiers accédés fréquemment |
| Standard-IA | 50% | Accès <1/mois |
| Glacier IR | 20% | Accès <1/trimestre |
| Glacier | 10% | Archives (retrieval 3-5h) |
| Deep Archive | 5% | Archives long terme (retrieval 12h) |

**Économies attendues** : ~60-70% sur stockage S3

## Réplication Cross-Region (Optionnel)

Pour haute disponibilité :

```hcl
module "storage" {
  source = "./modules/storage"
  
  cdnu_name                          = "yaounde"
  enable_replication                 = true
  replication_destination_bucket_arn = "arn:aws:s3:::backup-bucket"
}
```

## Usage

```hcl
module "storage" {
  source = "./modules/storage"
  
  project_name = "cdnu-cloud"
  cdnu_name    = "yaounde"
  
  cors_allowed_origins = [
    "https://cdnu-yaounde.cm",
    "https://api.cdnu-yaounde.cm"
  ]
}
```

## Outputs

- `bucket_id` : ID du bucket S3
- `bucket_arn` : ARN du bucket
- `bucket_domain_name` : Domain name S3
- `logs_bucket_id` : ID du bucket de logs

## Sécurité

- ✅ Encryption at rest (AES-256)
- ✅ Encryption in transit (HTTPS uniquement)
- ✅ Block public access
- ✅ Versioning (protection delete accidentel)
- ✅ Logging activé
- ✅ IAM policies restrictives

## Monitoring

- Métriques CloudWatch activées
- Alarme réplication lag (si réplication activée)
- Logs d'accès dans bucket séparé

## Coût Estimé

Pour 1TB de données avec lifecycle :

| Mois | Standard | Avec Lifecycle | Économie |
|------|----------|----------------|----------|
| 1 | $23 | $23 | 0% |
| 2 | $23 | $18 | 22% |
| 3 | $23 | $12 | 48% |
| 6 | $23 | $7 | 70% |

**ROI** : Lifecycle policies s'amortissent dès le 2ème mois.
