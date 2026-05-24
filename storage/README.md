# RAPPORT TECHNIQUE - MODULE DE STOCKAGE D'OBJETS (STORAGE)
## GROUPE 5 - SERVICES MANAGÉS
### PROJET DE CLOUD NATIONAL DES CDNUs DU CAMEROUN

---

## 1. COLLABORATEURS DU GROUPE 5

Ce module a été conçu, développé et testé par l'équipe du Groupe 5 :
1. NEUSSI NJIETCHEU PATRICE EUGENE (21T2894) - Responsable de lot
2. NDONKOU FRANCK (21T2254)
3. NDOMBOU KAMDEM (21T2552)
4. FOTSING ENGOULOU SIMON GAETAN (21Q2024)
5. FANDJA DE TCHOUA ANNAELLE ORLANE

---

## 2. PRÉSENTATION DU MODULE STORAGE

Le stockage des documents administratifs, des cours en ligne, des thèses et des fichiers multimédias pour l'ensemble des 11 Centres de Développement du Numérique Universitaire (CDNU) du Cameroun est pris en charge par le module `storage`.

Ce module provisionne une architecture de stockage d'objets résiliente et sécurisée s'appuyant sur Amazon S3 (Simple Storage Service) et intègre des politiques avancées de gestion du cycle de vie des données (FinOps) pour optimiser drastiquement les coûts d'hébergement récurrents.

---

## 3. ARCHITECTURE TECHNIQUE DU STOCKAGE

Pour chaque CDNU déployé, le module crée deux buckets distincts afin de séparer les données utiles des métadonnées de supervision :

### 3.1 Le Bucket Principal de Données CDNU
- Rôle : Stocke l'ensemble des fichiers applicatifs et universitaires (cours, images, PDF).
- Isolation : Accès strictement privé. L'option Block Public Access d'AWS S3 est activée globalement pour empêcher tout accès public accidentel.
- Chiffrement : Chiffrement côté serveur par défaut à l'aide de clés gérées par Amazon S3 (SSE-S3), garantissant que toutes les données écrites sur le disque physique sont chiffrées de manière transparente.
- Versioning : Activé pour protéger contre l'écrasement involontaire ou la suppression malveillante de fichiers critiques (ex. attaques par ransomware).

### 3.2 Le Bucket de Logs d'Accès Dédié (Access Logging Bucket)
- Rôle : Enregistre de manière exhaustive toutes les requêtes (lectures, écritures, suppressions) effectuées sur le bucket principal de données à des fins d'audit de sécurité et de traçabilité légale.
- Isolation : Configuré de manière isolée pour empêcher toute modification ou suppression des journaux d'accès, constituant une preuve inaltérable pour le Groupe 7 (Sécurité).

---

## 4. STRATÉGIE FINOPS ET GESTION DU CYCLE DE VIE DES DONNÉES

Le stockage de documents universitaires représente historiquement plus de 70% du coût récurrent d'un cloud national. Afin d'éviter l'explosion des factures d'AWS, le module applique une politique rigoureuse de transition automatique entre les différentes classes de stockage d'Amazon S3 (Standard, Standard-IA, Glacier Instant Retrieval, Glacier Flexible Retrieval et Glacier Deep Archive).

### 4.1 Règle 1 : Transition des données actives
1. **Standard** (0 à 30 jours) : Fichiers fréquemment accédés au cours du mois de création.
2. **Glacier Instant Retrieval** (31 à 120 jours) : Fichiers peu accédés, mais nécessitant une récupération immédiate (en quelques millisecondes) s'ils sont sollicités. Coût de stockage réduit de 60%.
3. **Glacier Flexible Retrieval** (121 à 210 jours) : Fichiers d'archive intermédiaires (retrait en 3 à 5 heures). Coût de stockage réduit de 85%.
4. **Glacier Deep Archive** (Après 210 jours) : Fichiers d'archive de longue durée ou historiques (retrait en 12 heures). Classe la moins coûteuse d'AWS (environ 1 dollar par To et par mois).

### 4.2 Règle 2 : Gestion des anciennes versions (Versioning Lifecycle)
- Les versions non courantes des objets (fichiers modifiés ou supprimés) sont automatiquement déplacées vers Glacier après 30 jours et supprimées définitivement après 90 jours.

### 4.3 Règle 3 : Nettoyage automatique des téléversements multipartites inachevés
- Les processus de téléversement multipartites (Multipart Uploads) qui échouent ou restent inachevés consomment de l'espace facturé. Le module les supprime automatiquement après 7 jours.

### 4.4 Règle 4 : Fichiers temporaires
- Tout fichier déposé dans le répertoire virtuel `temp/` est expiré et supprimé automatiquement de manière définitive au bout de 7 jours.

### 4.5 Règle 5 : Gestion du cycle de vie des logs
- Les journaux d'accès (logs) sont déplacés vers Standard-IA après 30 jours, vers Glacier après 90 jours et détruits définitivement après 365 jours (durée légale de conservation des logs).

---

## 5. ANALYSE COMPARATIVE DES COÛTS (FINOPS)

Le tableau ci-dessous modélise l'impact financier de notre politique de cycle de vie pour 1 To de documents stockés au cours d'une année :

| Mois d'existence | Classe de Stockage | Coût mensuel standard | Coût avec Lifecycle G5 | Économie Générée |
|------------------|--------------------|-----------------------|------------------------|------------------|
| Mois 1 | S3 Standard | 23,00 USD | 23,00 USD | 0% (Phase active) |
| Mois 2 | Glacier IR | 23,00 USD | 4,00 USD | 82% d'économie |
| Mois 5 | Glacier Flexible | 23,00 USD | 3,60 USD | 84% d'économie |
| Mois 8 | Glacier Deep | 23,00 USD | 0,99 USD | 95% d'économie |

---

## 6. SÉCURITÉ APPLICATIVE ET EN TRANSIT (BUCKET POLICIES)

Toutes les transactions réseau vers les buckets du Groupe 5 sont sécurisées par une politique de bucket (`aws_s3_bucket_policy`) stricte :
- **Mandat TLS / HTTPS** : La politique rejette explicitement toute action (`s3:*`) si la requête n'utilise pas le protocole sécurisé HTTPS (vérification de la condition `aws:SecureTransport` à `false`).
- **Configuration CORS (Cross-Origin Resource Sharing)** : Le module intègre des règles CORS configurables afin de permettre aux navigateurs web des étudiants de téléverser directement des fichiers vers les buckets S3 sans passer par les serveurs de l'API (direct upload), allégeant la charge réseau de l'infrastructure ECS Fargate (Groupe 6).

---

## 7. PROTOCOLE D'INTÉGRATION ET USAGE DANS TERRAFORM

Pour déclarer le stockage d'un nouveau CDNU dans le code global de l'infrastructure, le module s'appelle de la manière suivante :

```hcl
module "storage_yaounde" {
  source = "./storage"

  project_name         = "cdnu-cloud-g5"
  cdnu_name            = "yaounde"
  cors_allowed_origins = ["https://yaounde.cdnu.edu.cm"]

  tags = {
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}
```
*Le module génère automatiquement le bucket de données principal et son bucket de logs d'audit associé avec les conventions de nommage unifiées nationales.*
