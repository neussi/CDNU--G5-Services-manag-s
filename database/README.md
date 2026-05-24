# RAPPORT TECHNIQUE - MODULE BASE DE DONNÉES (DATABASE)
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

## 2. PRÉSENTATION DU MODULE DATABASE

Le sous-système de persistance des données repose sur le module `database`. Il a pour objectif de provisionner une base de données relationnelle centralisée, hautement disponible et sécurisée pour l'ensemble des Centres de Développement du Numérique Universitaire (CDNU) du Cameroun. 

Ce module orchestre les composants AWS suivants :
- Amazon RDS PostgreSQL (Base de données relationnelle managée).
- AWS Secrets Manager (Gestion automatique des identifiants d'accès).
- AWS Backup (Politique nationale de sauvegarde et restauration).
- AWS KMS (Chiffrement unifié au repos).
- Amazon CloudWatch (Supervision et gestion des alertes d'exploitation).

---

## 3. ARCHITECTURE ET CONFIGURATION TECHNIQUE DÉTAILLÉE

### 3.1 Moteur PostgreSQL et Dimensionnement
La base de données centrale utilise le moteur open-source PostgreSQL en version stable **15.18**. Ce choix garantit la compatibilité avec les standards modernes et permet l'exploitation des fonctionnalités de partitionnement pour isoler les données de chaque CDNU si nécessaire.
- Classe d'instance : `db.t3.micro` par défaut pour l'environnement académique et de test (extensible sans interruption de service vers des classes de production `db.m6g` ou `db.r6g` à base de processeurs AWS Graviton pour une meilleure efficacité énergétique et tarifaire).
- Type de Stockage : Volume General Purpose SSD de type **GP3** d'une capacité initiale de 20 Go. Le stockage GP3 est configuré pour délivrer 3000 IOPS de base et un débit de 125 Mo/s de manière stable, sans surcoût, offrant des performances bien supérieures au stockage GP2 conventionnel.
- Allocation dynamique : L'autoscaling du stockage est activé pour permettre au volume de s'étendre automatiquement jusqu'à un maximum de 100 Go en cas de saturation de l'espace disque.

### 3.2 Sécurité et Chiffrement au repos (KMS)
Toutes les données stockées dans la base de données relationnelle (tables, index, journaux de transactions, clichés de sauvegarde) sont systématiquement chiffrées au repos (Encryption at Rest) à l'aide de l'algorithme standard industriel AES-256. 
- Ce chiffrement est assuré via une clé KMS (Key Management Service) spécifiquement créée et gérée par notre module, empêchant toute lecture non autorisée sur les disques physiques d'AWS.

### 3.3 Isolation Réseau (Subnet Group et Security Group)
L'instance RDS PostgreSQL est rendue strictement privée :
- Subnet Group privé : L'instance est associée à un groupe de sous-réseaux qui ne contient aucun point d'accès public vers Internet.
- Security Group restrictif : Un groupe de sécurité dédié n'autorise les connexions entrantes que sur le port standard de PostgreSQL (5432). Ces flux sont filtrés par adresses IP (CIDR) ou par groupes de sécurité sources pour n'autoriser que les serveurs de l'API (ECS Fargate gérés par le Groupe 6) et les machines d'administration réseau. Tout autre trafic est systématiquement rejeté.

---

## 4. INTEGRATION AVEC SECRETS MANAGER (SÉCURITÉ APPLICATIVE)

Pour respecter la directive interdisant le stockage de mots de passe en clair dans le code source de l'infrastructure ou dans les dépôts Git, nous avons mis en oeuvre une intégration poussée avec AWS Secrets Manager :
1. Terraform génère un mot de passe d'administration robuste lors du premier déploiement.
2. Ce mot de passe est immédiatement transmis à un coffre-fort de secrets sécurisé (AWS Secrets Manager) créé par notre module.
3. L'API applicative déployée sur ECS Fargate (Groupe 6) lit dynamiquement ce secret au démarrage via son rôle IAM de tâche pour s'authentifier auprès de PostgreSQL. Cela évite toute exposition accidentelle de secrets.

---

## 5. POLITIQUE DE SAUVEGARDE ET CONTINUITÉ D'ACTIVITÉ (AWS BACKUP)

La continuité d'activité du cloud national des CDNUs s'appuie sur une politique de sauvegarde multi-niveaux centralisée via le service managé AWS Backup. Ce plan est autonome et applique les règles suivantes :

### 5.1 Règles de Clichés et Rétention
- Sauvegardes Quotidiennes : Un cliché de sauvegarde (snapshot) est généré automatiquement chaque jour à 03h00 (UTC). Ce cliché est conservé dans notre coffre-fort sécurisé (Backup Vault) pendant une durée de **7 jours**.
- Sauvegardes Hebdomadaires : Un cliché complet est généré chaque dimanche à 04h00 (UTC) et conservé pendant **4 semaines** (28 jours) avant d'être expiré et supprimé automatiquement.

### 5.2 Chiffrement des sauvegardes
Toutes les archives de sauvegarde sont chiffrées séparément au sein d'un coffre de sauvegarde (`aws_backup_vault`) protégé par sa propre clé KMS, assurant une double couche de protection des données critiques de l'enseignement supérieur.

---

## 6. SUPERVISION ET METRIQUES D'EXPLOITATION (CLOUDWATCH)

Pour assurer une maintenance proactive et une détection immédiate des pannes, le module installe automatiquement 4 alarmes CloudWatch :
- **Alarme CPU élevé** : Se déclenche si la consommation de processeur de l'instance dépasse 85% pendant plus de 5 minutes (indique une saturation applicative).
- **Alarme Stockage saturé** : Se déclenche si l'espace disque libre descend en dessous de 2 Go.
- **Alarme Connexions saturées** : Se déclenche si le nombre de connexions SQL simultanées dépasse 80% du maximum autorisé par la classe d'instance.
- **Alarme Memory épuisée** : Se déclenche si la mémoire vive disponible descend sous le seuil critique de 100 Mo.

Ces alarmes transmettent leurs métriques au tableau de bord centralisé du Groupe 8 (Supervision) pour l'envoi d'alertes automatiques aux ingénieurs système.

---

## 7. PROTOCOLE D'INTÉGRATION ET DE VÉRIFICATION APPLICATIVE

Lorsqu'un conteneur applicatif développé par le Groupe 6 doit se connecter à cette base de données, la cinématique d'intégration est la suivante :

### 7.1 Récupération des informations de connexion
L'API a besoin des informations exportées par les outputs de notre module :
- Host de connexion : `rds_endpoint` (ex. `cdnu-cloud-g5-postgres.c1q8m02k8sti.eu-central-1.rds.amazonaws.com:5432`)
- Utilisateur : `cdnu_admin`
- Secret d'accès : `rds_secret_arn` (l'ARN AWS Secrets Manager pour récupérer le mot de passe SQL de manière sécurisée).

### 7.2 Connexion en ligne de commande (Vérification et Diagnostic)
Pour tester manuellement la connectivité depuis une instance interne du VPC, utilisez l'outil client standard `psql` :
```bash
psql -h cdnu-cloud-g5-postgres.c1q8m02k8sti.eu-central-1.rds.amazonaws.com -U cdnu_admin -d postgres
```
*Saisir ensuite le mot de passe récupéré de manière sécurisée depuis la console AWS Secrets Manager.*
