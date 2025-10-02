# 🚀 Guide de Déploiement Multi-Domaines sur VPS

Ce guide explique comment déployer une application Django + Vue.js avec plusieurs domaines sur un seul VPS, en utilisant Docker, nginx-proxy et Let's Encrypt.

## 📋 Architecture

```
┌─────────────────────────────────────────┐
│          Internet (Port 80/443)         │
└──────────────────┬──────────────────────┘
                   │
         ┌─────────▼──────────┐
         │  Nginx Reverse     │
         │  Proxy + SSL       │
         └─────────┬──────────┘
                   │
        ┌──────────┴──────────┐
        │                     │
   ┌────▼─────┐        ┌─────▼────────┐
   │ Frontend │        │   Backend    │
   │   Vue.js │        │   Django     │
   │  (port   │        │   (8010)     │
   │   80)    │        └──────┬───────┘
   └──────────┘               │
                      ┌───────┴────────┐
                      │                │
                ┌─────▼─────┐    ┌────▼────┐
                │   Redis   │    │ Celery  │
                │  (6379)   │    │ Worker  │
                └───────────┘    │ + Beat  │
                                 └─────────┘
```

## 🛠️ Stack Technique

- **Frontend**: Vue.js 3 + Vite (servi par Nginx)
- **Backend**: Django + Gunicorn
- **Cache/Queue**: Redis 7 Alpine
- **Task Queue**: Celery Worker + Celery Beat
- **Reverse Proxy**: nginx-proxy (jwilder)
- **SSL**: Let's Encrypt (automatique)
- **Réseau**: Docker network externe partagé

## 📦 Structure des Fichiers

```
deploy/
├── nginx/
│   └── docker-compose.yml          # Reverse proxy + Let's Encrypt
├── django/
│   ├── Dockerfile                  # Image Django
│   ├── docker-compose.prod.yml     # Config production backend
│   └── start.sh                    # Script de démarrage
├── vue/
│   ├── Dockerfile                  # Image Vue.js (multi-stage)
│   └── docker-compose.prod.yml     # Config production frontend
└── README.md
```

## 🚦 Déploiement Étape par Étape

### 1️⃣ Créer le Réseau Docker Partagé

```bash
docker network create net
```

> **Note**: Le réseau `net` permet à tous les conteneurs de communiquer entre eux.

### 2️⃣ Démarrer le Reverse Proxy

```bash
cd deploy/nginx
docker-compose up -d
```

Ce conteneur va :
- ✅ Écouter sur les ports 80 et 443
- ✅ Gérer automatiquement le routing vers les bons conteneurs
- ✅ Générer et renouveler les certificats SSL Let's Encrypt

**⚠️ Important**: Modifier l'email dans `docker-compose.yml` :
```yaml
DEFAULT_EMAIL: "votre-email@domain.com"
```

### 3️⃣ Déployer le Backend Django

```bash
cd deploy/django
docker-compose -f docker-compose.prod.yml up -d
```

**Services déployés** :
- **api** : Django + Gunicorn (port 8010)
- **redis** : Cache et broker Celery (port 6379)
- **celery_prod** : Worker pour tâches asynchrones
- **celery-beat-prod** : Scheduler pour tâches périodiques

**Configuration requise** :
- Créer un fichier `.env` avec les variables d'environnement
- `VIRTUAL_HOST`: domaine de l'API (ex: `goals-api.nbesoro.com`)
- `LETSENCRYPT_HOST`: même domaine pour SSL
- `DATABASE_URL`: connexion PostgreSQL distante
- Variables Celery : `CELERY_BROKER_URL`, `CELERY_RESULT_BACKEND`

**Fonctionnalités** :
- ✅ Attente automatique de la DB distante (30 tentatives)
- ✅ Migrations auto au démarrage
- ✅ Redis pour cache et queues Celery
- ✅ Celery Worker pour tâches async
- ✅ Celery Beat pour tâches planifiées
- ✅ Mode DEBUG = création auto du superuser `admin/admin123`
- ✅ Production = Gunicorn avec 3 workers
- ✅ Volumes persistants pour static/media

### 4️⃣ Déployer le Frontend Vue.js

```bash
cd deploy/vue
docker-compose -f docker-compose.prod.yml up -d
```

**Configuration requise** :
```yaml
VIRTUAL_HOST: productivity.nbesoro.com
LETSENCRYPT_HOST: productivity.nbesoro.com
VITE_API_BASE_URL: https://goals-api.nbesoro.com
```

**Fonctionnalités** :
- ✅ Build multi-stage (optimisé)
- ✅ Nginx avec support Vue Router (SPA)
- ✅ Cache statique 1 an pour assets
- ✅ Image depuis GitHub Container Registry

## 🔧 Variables d'Environnement Importantes

### Backend Django
| Variable | Description | Exemple |
|----------|-------------|---------|
| `VIRTUAL_HOST` | Domaine API | `goals-api.nbesoro.com` |
| `LETSENCRYPT_HOST` | Domaine SSL | `goals-api.nbesoro.com` |
| `LETSENCRYPT_EMAIL` | Email Let's Encrypt | `bonjour@nbesoro.com` |
| `DATABASE_URL` | DB PostgreSQL | `postgresql://user:pass@host/db` |
| `DEBUG` | Mode debug | `False` en production |
| `SECRET_KEY` | Clé Django | Générer avec `python -c 'from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())'` |
| `CELERY_BROKER_URL` | URL Redis pour Celery | `redis://redis:6379/0` |
| `CELERY_RESULT_BACKEND` | Backend résultats | `redis://redis:6379/0` |

### Frontend Vue.js
| Variable | Description | Exemple |
|----------|-------------|---------|
| `VIRTUAL_HOST` | Domaine frontend | `productivity.nbesoro.com` |
| `VITE_API_BASE_URL` | URL de l'API | `https://goals-api.nbesoro.com` |

## 🎯 Commandes Utiles

### Vérifier les logs
```bash
# Reverse proxy
docker logs -f reverse-proxy

# Backend API
docker-compose -f deploy/django/docker-compose.prod.yml logs -f api

# Celery Worker
docker-compose -f deploy/django/docker-compose.prod.yml logs -f celery_prod

# Celery Beat
docker-compose -f deploy/django/docker-compose.prod.yml logs -f celery-beat-prod

# Redis
docker-compose -f deploy/django/docker-compose.prod.yml logs -f redis

# Frontend
docker-compose -f deploy/vue/docker-compose.prod.yml logs -f
```

### Redémarrer un service
```bash
docker-compose -f deploy/django/docker-compose.prod.yml restart
```

### Mettre à jour une image
```bash
docker-compose -f deploy/vue/docker-compose.prod.yml pull
docker-compose -f deploy/vue/docker-compose.prod.yml up -d
```

### Voir les conteneurs actifs
```bash
docker ps
```

## 🔒 Sécurité

- ✅ SSL/TLS automatique via Let's Encrypt
- ✅ Renouvellement automatique des certificats
- ✅ Headers de sécurité configurés par nginx-proxy
- ⚠️ Penser à configurer CORS dans Django pour le domaine frontend
- ⚠️ Utiliser des variables d'environnement pour les secrets

## 🐛 Troubleshooting

### Le SSL ne se génère pas
1. Vérifier que les DNS pointent bien vers le VPS
2. Vérifier les logs : `docker logs letsencrypt-helper`
3. Attendre 1-2 minutes après le premier démarrage

### L'API ne répond pas
1. Vérifier que le backend est démarré : `docker ps`
2. Vérifier les logs : `docker-compose -f deploy/django/docker-compose.prod.yml logs api`
3. Vérifier que `VIRTUAL_HOST` est correct
4. Tester : `curl http://localhost:8010/admin/` depuis le VPS

### Celery ne traite pas les tâches
1. Vérifier que Redis est actif : `docker-compose -f deploy/django/docker-compose.prod.yml ps redis`
2. Vérifier les logs du worker : `docker-compose -f deploy/django/docker-compose.prod.yml logs celery_prod`
3. Tester la connexion Redis : `docker exec -it <redis_container> redis-cli ping`
4. Vérifier les variables `CELERY_BROKER_URL` et `CELERY_RESULT_BACKEND` dans `.env`

### Erreur CORS
Ajouter dans Django `settings.py` :
```python
CORS_ALLOWED_ORIGINS = [
    "https://productivity.nbesoro.com",
]
```

## 📝 Notes

- **Images** : Frontend et Backend utilisent des images pré-buildées depuis GitHub Container Registry (`ghcr.io`)
- **Volumes** : Les fichiers static/media sont persistés via volumes Docker (à configurer dans `.env`)
- **Redis** : Les données Redis sont persistées dans le volume `redis_data`
- **Celery** : Le worker et beat utilisent la même image que l'API
- **SSL** : Les volumes nginx-proxy persistent les certificats SSL
- **Script start.sh** : Gère automatiquement dev vs production selon `DEBUG`
- **Volumes locaux** : Modifier les chemins `./chemin_vers_static_depuis_vps/` dans `docker-compose.prod.yml`

## 🔗 Ressources

- [nginx-proxy](https://github.com/nginx-proxy/nginx-proxy)
- [letsencrypt-nginx-proxy-companion](https://github.com/nginx-proxy/acme-companion)
- [Docker Networks](https://docs.docker.com/network/)
