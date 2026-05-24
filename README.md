# RAPPORT TECHNIQUE ET MANUEL D'EXPLOITATION
## GROUPE 5 - SERVICES MANAGÉS (STOCKAGE, BASE DE DONNÉES ET REGISTRE DE CONTENEURS)
### PROJET NATIONAL DE CLOUD DES CENTRES DE DÉVELOPPEMENT DU NUMÉRIQUE UNIVERSITAIRE (CDNU) DU CAMEROUN

---

## 1. INTRODUCTION ET DESCRIPTION DU PERIMÈTRE TECHNIQUE

Dans le cadre de la modernisation et de l'unification des infrastructures numériques de l'enseignement supérieur au Cameroun, ce projet met en oeuvre une infrastructure Cloud souveraine et hautement résiliente sur Amazon Web Services (AWS) pour interconnecter les 11 Centres de Développement du Numérique Universitaire (CDNU). 

Le Groupe 5 est responsable du lot "Services Managés". Ce lot regroupe l'ensemble des composants de persistance des données, de stockage de fichiers distribués et de gestion des artefacts applicatifs nécessaires au fonctionnement de la plateforme nationale. Le périmètre technique confié au Groupe 5 comprend trois piliers majeurs :
1. La base de données relationnelle centrale PostgreSQL sous forme de service managé Amazon RDS, assurant la cohérence et la centralisation des données de l'ensemble des 11 CDNUs.
2. Le stockage d'objets Amazon S3 comprenant 11 buckets distincts (un par CDNU) dotés de politiques strictes de cycle de vie et d'archivage automatique pour l'optimisation des coûts (FinOps).
3. Le registre de conteneurs privé Amazon ECR destiné à stocker et analyser les images de conteneurs Docker de l'API applicative développée par les autres groupes de travail.

---

## 2. ARCHITECTURE TECHNIQUE DÉTAILLÉE DES SERVICES MANAGÉS

### 2.1 Amazon RDS PostgreSQL
La base de données centrale est déployée sous forme d'instance Amazon RDS PostgreSQL version 15.18. Afin de concilier les contraintes de performance académique et l'optimisation budgétaire, les choix de configuration suivants ont été mis en oeuvre :
- Classe d'instance : db.t3.micro (2 vCPUs, 1 Go de RAM), extensible vers des classes supérieures (ex. db.m6g) en cas de montée en charge.
- Stockage : 20 Go de type GP3 avec chiffrement obligatoire au repos via une clé KMS (Key Management Service) gérée par le client. Le type GP3 offre un débit de 3000 IOPS de base sans coût additionnel, ce qui est supérieur au stockage GP2 classique.
- Haute disponibilité : Support de la topologie Multi-AZ (désactivable via la variable multi_az pour limiter les coûts hors production), permettant la réplication synchrone vers une zone de disponibilité secondaire avec basculement automatique.
- Sécurité : L'accès à la base de données est exclusivement privé. L'instance RDS est rattachée à un Subnet Group composé uniquement de sous-réseaux isolés, sans adresse IP publique, empêchant toute tentative de connexion directe depuis Internet. Les identifiants d'administration (nom d'utilisateur et mot de passe de connexion) sont automatiquement provisionnés dans AWS Secrets Manager.

### 2.2 Stockage Amazon S3
Conformément aux directives FinOps visant à réduire au maximum l'empreinte financière du stockage de données (qui représente historiquement plus de 70% du coût d'un tel projet), chaque CDNU dispose de son propre bucket S3 principal et d'un bucket de logs d'accès dédié.
- Chiffrement et Transport : Tous les buckets sont configurés avec le chiffrement côté serveur par défaut SSE-S3. De plus, une politique de bucket explicite rejette systématiquement toute requête non sécurisée (HTTP standard), forçant l'utilisation exclusive du protocole HTTPS (TLS 1.2+).
- Sécurité d'Accès : L'accès public est bloqué au niveau du bucket (Block Public Access) afin d'éviter toute fuite accidentelle de données universitaires.
- Cycle de Vie des Données (Lifecycle Configuration) : Pour optimiser les coûts, une politique de transition automatique à cinq règles a été mise en place :
  - Règle 1 : Les objets actifs passent dans la classe S3 Glacier Instant Retrieval (GLACIER_IR) après 30 jours, puis dans la classe Glacier Flexible Retrieval (GLACIER) après 120 jours, et enfin dans S3 Glacier Deep Archive (DEEP_ARCHIVE) après 210 jours pour un archivage à très faible coût.
  - Règle 2 : Le versioning est activé sur les buckets pour protéger contre les suppressions accidentelles. Les versions non courantes des objets sont transférées vers Glacier après 30 jours et définitivement expirées après 90 jours.
  - Règle 3 : Les téléversements multipartites inachevés sont nettoyés automatiquement après 7 jours pour éviter de payer pour de l'espace disque inutilisé.
  - Règle 4 : Les fichiers stockés dans le préfixe temporaire "temp/" sont automatiquement expirés après 7 jours.
  - Règle 5 : Les journaux d'accès stockés dans le préfixe "logs/" sont déplacés vers Standard Infrequent Access (STANDARD_IA) après 30 jours, Glacier après 90 jours et définitivement supprimés après 365 jours.

### 2.3 Amazon ECR (Elastic Container Registry)
Le registre privé ECR accueille les images Docker de l'API nationale.
- Sécurité et Analyse : Le scan au moment du push (scan_on_push) est activé. Chaque image poussée est analysée statiquement par rapport à la base de données de vulnérabilités CVE. Si une faille critique est détectée, une alarme CloudWatch est déclenchée.
- Cycle de Vie des Images : Pour éviter l'accumulation indéfinie d'images Docker obsolètes (qui consomment de l'espace de stockage facturé), une politique de cycle de vie conserve au maximum les 10 dernières images étiquetées avec un préfixe de version (v*) et purge automatiquement les images non étiquetées (untagged) après 7 jours.

---

## 3. INTÉGRATION AVEC LE PROJET GÉNÉRAL (INTER-GROUPES)

L'architecture Cloud des CDNUs est découpée en plusieurs modules développés par différents groupes d'étudiants. Le Groupe 5 s'intègre au coeur de cet écosystème de la manière suivante :

### 3.1 Intégration Réseau (Groupe 4 - IaC Réseau)
Le Groupe 4 conçoit la topologie multi-région, les VPCs de chaque CDNU et les Transit Gateways pour interconnecter les sites. 
- Dans la configuration globale unifiée, le module RDS PostgreSQL du Groupe 5 reçoit en argument la liste des IDs de sous-réseaux privés (subnet_ids) créés par le Groupe 4.
- Le groupe de sécurité (security_group) de la base de données RDS n'autorise les connexions sur le port 5432 que depuis les blocs d'adresses IP (CIDR) des VPCs des CDNUs gérés par le Groupe 4.

### 3.2 Intégration Applicative (Groupe 6 - API & Conteneurs)
Le Groupe 6 est en charge du déploiement de l'API sur AWS ECS Fargate et de la configuration de l'Application Load Balancer (ALB).
- L'API du Groupe 6 récupère l'URL du registre ECR créé par le Groupe 5 pour y stocker et déployer les conteneurs de l'application.
- Pour se connecter à la base de données, l'API du Groupe 6 récupère l'adresse (Endpoint RDS) générée par notre module, ainsi que les informations d'authentification stockées de manière sécurisée dans AWS Secrets Manager.

### 3.3 Intégration Sécurité (Groupe 7 - IAM & Droits)
Le Groupe 7 gère les politiques de moindre privilège et les rôles IAM.
- Le Groupe 7 utilise les ARNs des buckets S3 du Groupe 5 pour générer des politiques IAM restrictives. Ces politiques permettent aux instances EC2 applicatives d'écrire et de lire uniquement dans leur propre bucket S3 correspondant (par exemple, l'instance de Buea ne peut pas accéder au bucket de Douala).

### 3.4 Intégration Supervision (Groupe 8 - Monitoring)
Le Groupe 8 déploie CloudWatch et configure les alertes.
- Le Groupe 8 exploite les alarmes CloudWatch créées par notre module concernant le niveau de stockage de la base RDS, le nombre de connexions simultanées, les échecs de sauvegarde d'AWS Backup et les vulnérabilités de conteneurs ECR pour envoyer des notifications automatiques (SMS / Email) aux administrateurs réseau nationaux.

---

## 4. PROCÉDURE DE TEST ET DE VALIDATION AUTONOME

Afin de valider le bon fonctionnement du code du Groupe 5 indépendamment des autres groupes de travail, nous avons configuré une infrastructure de test autonome qui s'appuie sur le VPC par défaut présent sur le compte AWS. Cette approche élimine toute dépendance extérieure et garantit un déploiement fiable.

### 4.1 Prérequis de Test
Pour exécuter les tests, vous devez vous situer dans le répertoire de travail dédié au Groupe 5 et disposer du binaire Terraform installé localement.
```bash
cd /home/npe-tech/Downloads/cdnu-projet-par-groupes/G5-Services-Manages
```

### 4.2 Étape 1 : Initialisation de l'Environnement
Cette étape configure le fournisseur AWS, télécharge les plugins nécessaires (AWS et Random) et initialise la liaison avec le backend S3 pour la persistance de l'état Terraform. Elle utilise l'option de reconfiguration pour s'assurer que les chemins sont corrects.
```bash
export AWS_ACCESS_KEY_ID="VOTRE_ACCESS_KEY_ID_ICI"
export AWS_SECRET_ACCESS_KEY="VOTRE_SECRET_ACCESS_KEY_ICI"
export AWS_DEFAULT_REGION="eu-central-1"

../bin/terraform init -reconfigure
```
*Attendu en cas de succès : Le message "Terraform has been successfully initialized!" s'affiche à l'écran.*

### 4.3 Étape 2 : Planification et Validation à Blanc
Le plan Terraform compile le code, interroge l'état actuel sur AWS et génère la liste exacte des modifications à apporter. C'est l'étape clé pour valider qu'aucune erreur de syntaxe ou logique n'est présente dans les modules du Groupe 5.
```bash
../bin/terraform plan
```
*Attendu en cas de succès : La planification se termine sans erreur et indique la création de 179 ressources. Ce chiffre correspond à :*
- *11 Buckets de stockage principaux + 11 Buckets de logs S3 (22 buckets au total).*
- *Les règles de cycle de vie et de transition pour chaque bucket.*
- *L'instance RDS PostgreSQL, son groupe de sous-réseaux, sa clé KMS dédiée et son secret dans AWS Secrets Manager.*
- *Le plan de sauvegarde AWS Backup avec ses règles de conservation quotidiennes et hebdomadaires.*
- *Le registre ECR, sa politique d'analyse de vulnérabilités et de rétention d'images.*
- *Les alarmes CloudWatch associées.*

### 4.4 Étape 3 : Application et Déploiement Réel (Optionnel)
Pour créer réellement les ressources sur le compte AWS, utilisez la commande d'application.
```bash
../bin/terraform apply -auto-approve
```
*Note : Cette commande prend environ 5 à 10 minutes, principalement pour le provisionnement physique de l'instance de base de données RDS PostgreSQL par AWS.*

### 4.5 Étape 4 : Validation des Outputs
Une fois le déploiement terminé, vérifiez que les outputs techniques indispensables pour les autres groupes sont correctement exportés.
```bash
../bin/terraform output
```
Cette commande affiche les informations de connexion que vous devez communiquer aux autres groupes (notamment l'URL d'ECR et le point de connexion de la base de données).

### 4.6 Étape 5 : Nettoyage des Ressources de Test
Pour éviter de consommer inutilement des crédits cloud sur le compte AWS après validation, détruisez l'ensemble des ressources créées lors du test.
```bash
../bin/terraform destroy -auto-approve
```

---

## 5. GARANTIE ABSOLUE DE SÉCURITÉ DES ACCÈS AWS

La sécurité de l'infrastructure nationale est une priorité critique. Conformément à la section 6 des Termes de Référence, aucune information sensible ou clé d'accès ne doit être publiée sur les dépôts de code partagés comme GitHub.

### 5.1 Rôle et Configuration du fichier `.gitignore`
Un fichier `.gitignore` a été rigoureusement configuré à la racine du projet du Groupe 5. Ce fichier indique à Git d'ignorer systématiquement les fichiers locaux contenant des données sensibles afin qu'ils ne soient jamais intégrés à l'index de suivi ou poussés vers GitHub.

Le fichier `.gitignore` exclut explicitement :
- `cdnu-admin_accessKeys.csv` : Le fichier physique contenant votre clé d'accès AWS (Access Key ID) et votre clé secrète (Secret Access Key).
- `terraform.tfvars` : Le fichier de variables contenant le mot de passe d'administration en clair de la base de données RDS PostgreSQL (`db_password`).
- `.terraform/` : Le répertoire local contenant les plugins de providers téléchargés et la configuration locale du backend de travail.
- `*.tfstate` et `*.tfstate.*` : Les fichiers d'état local de Terraform qui contiennent une copie en clair de l'ensemble de l'infrastructure et de ses secrets.
- `*.pdf` : Le document des Termes de Référence pour éviter d'encombrer le dépôt avec des fichiers binaires lourds.

### 5.2 Commandes de Vérification de l'Exclusion
Vous pouvez à tout moment vérifier que les fichiers sensibles ne sont pas suivis par Git en exécutant la commande de statut :
```bash
git status
```
*Attendu : Les fichiers cdnu-admin_accessKeys.csv et terraform.tfvars ne doivent jamais apparaître dans la liste des fichiers modifiés ou non suivis prêts à être ajoutés au commit.*

Si vous souhaitez vérifier précisément quels fichiers sont actuellement suivis dans votre dépôt local pour être absolument certain qu'aucun secret n'a été indexé par erreur, exécutez la commande suivante :
```bash
git ls-files
```
*Attendu : Seuls les fichiers d'infrastructure généraux (.tf, .gitignore, README.md) doivent apparaître dans la liste. Aucun fichier d'accès ou d'état local ne doit y figurer.*
