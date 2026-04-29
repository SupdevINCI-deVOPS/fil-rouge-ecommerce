# Fil Rouge E-Commerce

Application e-commerce complète, conteneurisée et déployée sur AWS avec pipeline CI/CD, monitoring et Infrastructure as Code.

---

## Table des matières

- [Architecture](#architecture)
- [Stack technique](#stack-technique)
- [Services](#services)
- [Prérequis](#prérequis)
- [Démarrage rapide](#démarrage-rapide)
- [Structure du projet](#structure-du-projet)
- [Infrastructure (Terraform)](#infrastructure-terraform)
- [Déploiement (Ansible)](#déploiement-ansible)
- [CI/CD (GitHub Actions)](#cicd-github-actions)
- [Monitoring](#monitoring)
- [Screenshots](#screenshots)

---

## Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│                         AWS EC2 (Paris eu-west-3)                │
│                                                                  │
│  ┌────────────┐    ┌────────────┐    ┌────────────────────────┐  │
│  │  Frontend  │───▶│  Backend   │───▶│       MongoDB          │  │
│  │  Vue.js 3  │    │  Express   │    │  + Mongo Express UI    │  │
│  │  :8000     │    │  :3000     │    │  :27017 / :8081        │  │
│  └────────────┘    └────────────┘    └────────────────────────┘  │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐    │
│  │                    Monitoring Stack                       │    │
│  │  Prometheus :9090  │  Grafana :3001  │  Loki :3100       │    │
│  │  Node Exporter :9100 │ cAdvisor :8080 │ Promtail :9080   │    │
│  │  MongoDB Exporter :9216                                   │    │
│  └──────────────────────────────────────────────────────────┘    │
└──────────────────────────────────────────────────────────────────┘

┌──────────────────┐    ┌──────────────────┐    ┌──────────────────┐
│   GitHub Actions │───▶│  Docker Hub      │───▶│  EC2 preprod/prod│
│   CI/CD Pipeline │    │  arosfa/images   │    │  Ansible Deploy  │
└──────────────────┘    └──────────────────┘    └──────────────────┘
```

---

## Stack technique

| Couche | Technologie |
|--------|------------|
| **Frontend** | Vue.js 3, Vite, Pinia, Vue Router, Tailwind CSS, daisyUI, Axios |
| **Backend** | Node.js 18, Express.js, JWT, bcrypt, Multer, prom-client |
| **Base de données** | MongoDB, Mongoose |
| **Containerisation** | Docker, Docker Compose |
| **Infrastructure** | Terraform (AWS EC2, VPC, Security Groups) |
| **Déploiement** | Ansible |
| **CI/CD** | GitHub Actions |
| **Monitoring** | Prometheus, Grafana, Loki, Promtail, cAdvisor, Node Exporter, MongoDB Exporter |
| **Cloud** | AWS (région Paris — eu-west-3) |

---

## Services

### Application principale (`docker-compose.yml`)

| Service | Image | Port | Description |
|---------|-------|------|-------------|
| `frontend` | Build local | 8000 | Application Vue.js |
| `backend` | Build local | 3000 | API REST Express.js |
| `mongo` | mongo | 27017 | Base de données MongoDB |
| `mongo-express` | mongo-express | 8081 | Interface admin MongoDB |
| `node-exporter` | prom/node-exporter | 9100 | Métriques système |

### Stack monitoring (`docker-compose.monitoring.yml`)

| Service | Image | Port | Description |
|---------|-------|------|-------------|
| `prometheus` | prom/prometheus | 9090 | Collecte de métriques |
| `grafana` | grafana/grafana | 3001 | Dashboards de visualisation |
| `loki` | grafana/loki | 3100 | Agrégation de logs |
| `promtail` | grafana/promtail | 9080 | Collecteur de logs Docker |
| `cadvisor` | gcr.io/cadvisor | 8080 | Métriques containers |
| `mongodb-exporter` | bitnami/mongodb-exporter | 9216 | Métriques MongoDB |
| `node-exporter` | prom/node-exporter | 9100 | Métriques système |

---

## Prérequis

- Docker & Docker Compose v2.x
- Node.js 18+ (développement local uniquement)
- Terraform >= 1.x (déploiement infra)
- Ansible >= 2.12 (déploiement serveur)
- AWS CLI configuré (déploiement infra)
- Compte Docker Hub (CI/CD)

---

## Démarrage rapide

### 1. Cloner le dépôt

```bash
git clone https://github.com/SupdevINCI-deVOPS/fil-rouge-ecommerce.git
cd fil-rouge-ecommerce
```

### 2. Configurer les variables d'environnement

```bash
cp backend/.env.example backend/.env
```

Contenu minimal du fichier `.env` :

```env
PORT=3000
MONGODB_URI=mongodb://admin:password@mongo:27017/ecommerce?authSource=admin
JWT_KEY=ecommerce_jwt_secret_2024
PUBLIC_DIR=/app/public
```

### 3. Lancer l'application

```bash
docker compose up -d --build
```

### 4. Lancer le monitoring (optionnel)

```bash
docker compose -f docker-compose.monitoring.yml up -d
```

### 5. Accéder aux services

| Service | URL |
|---------|-----|
| Frontend | http://localhost:8000 |
| Backend API | http://localhost:3000 |
| Mongo Express | http://localhost:8081 |
| Grafana | http://localhost:3001 (admin/admin) |
| Prometheus | http://localhost:9090 |

---

## Structure du projet

```
fil-rouge-ecommerce/
├── .github/workflows/
│   └── ci-cd.yml              # Pipeline GitHub Actions
├── backend/
│   ├── Dockerfile
│   ├── app.js
│   ├── auth.js                # Middleware JWT
│   ├── upload.js              # Gestion des fichiers (Multer)
│   ├── bin/www                # Point d'entrée Node.js
│   ├── controllers/           # Logique métier (admin, seller, user)
│   ├── models/                # Schémas Mongoose
│   ├── routes/                # Routes Express
│   └── mongo-entrypoint/      # Script d'initialisation MongoDB
├── frontend/
│   ├── Dockerfile
│   ├── vite.config.js
│   └── src/
│       ├── views/             # Pages (Home, Login, Register, Dashboard, Admin…)
│       ├── components/        # Composants réutilisables
│       ├── stores/            # État global Pinia
│       └── router/            # Configuration des routes
├── infra/
│   ├── terraform/
│   │   ├── main.tf            # Ressources AWS
│   │   ├── variables.tf       # Variables
│   │   ├── outputs.tf         # Sorties (IP, URLs…)
│   │   └── environments/
│   │       ├── preprod/terraform.tfvars
│   │       └── prod/terraform.tfvars
│   └── ansible/
│       ├── playbook.yml       # Playbook de déploiement
│       ├── inventory.ini      # Inventaire des serveurs
│       └── env/backend.env    # Variables d'environnement backend
├── monitoring/
│   ├── prometheus/prometheus.yml
│   ├── grafana/provisioning/
│   │   ├── dashboards/        # Dashboard JSON auto-provisionné
│   │   └── datasources/       # Prometheus + Loki
│   ├── loki/loki-config.yml
│   └── promtail/promtail-config.yml
├── screenshots/               # Captures d'écran de l'application
├── docker-compose.yml
└── docker-compose.monitoring.yml
```

---

## Infrastructure (Terraform)

L'infrastructure est provisionnée sur **AWS Paris (eu-west-3)** via Terraform, avec deux environnements indépendants.

### Ressources créées

- VPC dédié par environnement
- Sous-réseau public
- Internet Gateway + table de routage
- Security Group avec règles d'entrée par port
- Paire de clés SSH (via `~/.ssh/id_ed25519.pub`)
- Instance EC2

### Comparaison des environnements

| Paramètre | Preprod | Prod |
|-----------|---------|------|
| VPC CIDR | `10.0.0.0/16` | `10.1.0.0/16` |
| AZ | `eu-west-3a` | `eu-west-3b` |
| Instance | `t3.micro` | `t3.small` |
| Disque | 20 GB | 30 GB |
| SSH | Ouvert (`0.0.0.0/0`) | IP restreinte uniquement |

### Ports ouverts (Security Group)

`22`, `3000`, `8000`, `8081`, `9090`, `3001`, `9100`

### Commandes Terraform

```bash
cd infra/terraform

# Initialiser
terraform init

# Déployer en preprod
terraform apply -var-file=environments/preprod/terraform.tfvars

# Déployer en prod
terraform apply -var-file=environments/prod/terraform.tfvars

# Détruire
terraform destroy -var-file=environments/preprod/terraform.tfvars
```

### Outputs disponibles après apply

```
instance_public_ip   → IP publique de l'instance
instance_public_dns  → DNS public
instance_id          → ID de l'instance AWS
ssh_command          → Commande SSH prête à l'emploi
app_url              → URL de l'application
grafana_url          → URL de Grafana
prometheus_url       → URL de Prometheus
environment          → Nom de l'environnement
```

---

## Déploiement (Ansible)

Ansible configure automatiquement les serveurs EC2 et déploie l'application.

### Étapes du playbook

1. Mise à jour des paquets système
2. Installation de Docker & Git
3. Installation de Docker Compose v2.24.0
4. Démarrage et activation de Docker au boot
5. Ajout de `ec2-user` au groupe `docker`
6. Création du répertoire `/opt/ecommerce`
7. Clone du dépôt GitHub (branche `develop` pour preprod)
8. Copie du fichier `.env` backend
9. Lancement de `docker compose up -d --build`
10. Lancement du monitoring (environnement prod uniquement)

### Commandes Ansible

```bash
cd infra/ansible

# Déployer sur preprod
ansible-playbook -i inventory.ini playbook.yml --limit preprod

# Déployer sur prod
ansible-playbook -i inventory.ini playbook.yml --limit prod
```

### Inventaire actuel

```ini
[preprod]
13.38.71.162 ansible_user=ec2-user ansible_ssh_private_key_file=~/.ssh/id_ed25519

[prod]
15.236.205.82 ansible_user=ec2-user ansible_ssh_private_key_file=~/.ssh/id_ed25519
```

---

## CI/CD (GitHub Actions)

Le pipeline `.github/workflows/ci-cd.yml` gère l'intégration et le déploiement continus.

### Déclencheurs

| Événement | Branche | Action |
|-----------|---------|--------|
| Push | `develop` | CI uniquement |
| Push | `main` | CI + Build + Deploy |
| Pull Request | `develop`, `main` | CI uniquement |

### Jobs

```
┌─────────┐    ┌─────────┐    ┌──────────────────┐    ┌─────────────┐
│   CI    │───▶│  Build  │───▶│  Deploy Preprod  │───▶│ Deploy Prod │
│ (tests) │    │(Docker) │    │                  │    │             │
└─────────┘    └─────────┘    └──────────────────┘    └─────────────┘
```

**Job CI :**
- Setup Node.js 18 avec cache npm
- Installation et tests backend
- Build frontend
- Analyse SonarCloud (non-bloquant)

**Job Build :**
- Build et push des images Docker vers Docker Hub
- Images taguées `:latest` et `:sha-commit`
- Cache des layers Docker via GitHub Actions

**Job Deploy :**
- SSH sur les serveurs cibles
- Pull des nouvelles images
- `docker compose up -d`

### Images Docker Hub

```
arosfa/ecommerce-backend:latest
arosfa/ecommerce-frontend:latest
```

### Secrets GitHub requis

| Secret | Description |
|--------|-------------|
| `DOCKER_USERNAME` | Identifiant Docker Hub |
| `DOCKER_PASSWORD` | Mot de passe Docker Hub |
| `SONAR_TOKEN` | Token SonarCloud |
| `SSH_PRIVATE_KEY` | Clé SSH privée pour les serveurs |
| `PREPROD_IP` | IP publique du serveur preprod |
| `PROD_IP` | IP publique du serveur prod |

---

## Monitoring

La stack de monitoring est entièrement auto-provisionnée via Docker Compose.

### Architecture monitoring

```
Docker containers ──▶ cAdvisor ──────────────────▶ Prometheus ──▶ Grafana
Système hôte      ──▶ Node Exporter ──────────────▶ Prometheus ──▶ Grafana
MongoDB           ──▶ MongoDB Exporter ────────────▶ Prometheus ──▶ Grafana
Backend API       ──▶ /metrics (prom-client) ──────▶ Prometheus ──▶ Grafana
Logs Docker       ──▶ Promtail ──▶ Loki ───────────────────────▶ Grafana
```

### Dashboard Grafana (auto-provisionné)

Le dashboard **"Ecommerce Global Monitoring"** inclut :

- **Backend** — Requêtes/sec par méthode, route et code HTTP
- **Backend** — Latence p95 des requêtes
- **MongoDB** — Connexions actives
- **Containers** — CPU, RAM, I/O par container (via cAdvisor)
- **Système** — CPU, RAM, Disque du serveur (via Node Exporter)
- **Logs** — Exploration en temps réel via Loki

### Prometheus scrape jobs

| Job | Cible | Intervalle |
|-----|-------|------------|
| prometheus | localhost:9090 | 15s |
| backend | backend:3000/metrics | 15s |
| node-exporter | node-exporter:9100 | 15s |
| mongodb-exporter | mongodb-exporter:9216 | 15s |
| cadvisor | cadvisor:8080 | 15s |

### Loki

- Rétention des logs : **7 jours**
- Collecte : logs stdout/stderr de tous les containers Docker
- Labels : nom du container, flux (stdout/stderr)

---

## Screenshots

<table>
  <tr>
    <td><img src="screenshots/home.png" alt="Accueil" width="300"/></td>
    <td><img src="screenshots/product.png" alt="Produit" width="300"/></td>
    <td><img src="screenshots/category.png" alt="Catégorie" width="300"/></td>
  </tr>
  <tr>
    <td align="center">Accueil</td>
    <td align="center">Produit</td>
    <td align="center">Catégorie</td>
  </tr>
  <tr>
    <td><img src="screenshots/shop.png" alt="Boutique" width="300"/></td>
    <td><img src="screenshots/dashboard.png" alt="Dashboard vendeur" width="300"/></td>
    <td><img src="screenshots/admin_home.png" alt="Admin" width="300"/></td>
  </tr>
  <tr>
    <td align="center">Boutique</td>
    <td align="center">Dashboard vendeur</td>
    <td align="center">Panel admin</td>
  </tr>
  <tr>
    <td><img src="screenshots/login.png" alt="Connexion" width="300"/></td>
    <td><img src="screenshots/register.png" alt="Inscription" width="300"/></td>
    <td><img src="screenshots/user_profile.png" alt="Profil" width="300"/></td>
  </tr>
  <tr>
    <td align="center">Connexion</td>
    <td align="center">Inscription</td>
    <td align="center">Profil utilisateur</td>
  </tr>
</table>

---

## Licence

MIT — voir [LICENSE](LICENSE)
