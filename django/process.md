# Dans ce fichier j'explique la une processuss de deploiement avec un vps ubuntu

1. Se connecter au serveur via ssh
   `ssh user@ip_address`

2. Creer une cle public rsa
```bash
# executer ce code et faite entrer à chaque question
ssh-keygen -m PEM -t rsa -b 4096

# céer un fichier authorized_keys
touch ~/.ssh/authorized_keys

# copy
cat ~/.ssh/id_rsa.pub > ~/.ssh/authorized_keys

# mettre à jour les permissions
chmod 600 ~/.ssh/authorized_keys
chmod 600 ~/.ssh/id_rsa

# copier le resultat de ce code (nous allons le coler dans un fichier local)
cat ~/.ssh/id_rsa
# se deconnecter du server
exit
```

3. Céer un fichier private_key.pem sur votre machine local ajouter le contenu que vous avez copié après cette commande `cat ~/.ssh/id_rsa`

Executer cette commande sur le fichier .pem pour les permissions:
```bash
chmod 400 private_key.pem
```

4. Se connecter à nouveau en utilisant le fichier le fichier .pem

```bash
ssh -i private_key.pem user@ip_address
```

5. Si vous êtes connecté alors tout est ok. On passe à l'étape suivante.

6. Installer docker

## Installer Docker

```bash
sudo apt update
sudo apt upgrade
sudo apt install apt-transport-https curl wget software-properties-common -y
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
sudo usermod -aG docker $USER
docker run hello-world && echo "Docker successfully installed and running"

```
si vous avez une erreur de permission, executer:

```bash
sudo usermod -aG docker $USER && newgrp docker
```

7. Configuration des fichiers static et media

## Settings.py
```python
STATIC_URL = "static/"
STATICFILES_DIRS = [BASE_DIR / "static"]
STATIC_ROOT = BASE_DIR / "staticfiles"


# Media files (uploads)
MEDIA_URL = "/media/"
MEDIA_ROOT = BASE_DIR / "media"
```

## urls.py

```python
from django.conf import settings
from django.urls import re_path
from django.conf.urls.static import static
from django.views.static import serve

urlpatterns = [
    re_path(r"^static/(?P<path>.*)$", serve, {"document_root": settings.STATIC_ROOT}),
    re_path(r"^media/(?P<path>.*)$", serve, {"document_root": settings.MEDIA_ROOT}),
]

# Serve media files in development
if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)

```

8. Creer les dossier static et media

```bash
mkdir static

mkdir media
```

9. Ajouter les permissions aux dossier
```bash
sudo chown -R 1000:1000 media

sudo chown -R 1000:1000 static
```

10. Créer une base PostgreSQL sur le serveur ubuntu

## Installer PostgreSQL sur Ubuntu
```bash
sudo apt update
sudo apt install postgresql postgresql-contrib
```

## Vérifier que PostgreSQL tourne
``` bash
sudo systemctl status postgresql
```

11. Créer un utilisateur PostgreSQL
```bash
sudo -u postgres psql
```

Ensuite:
```sql
CREATE USER tyaouser WITH PASSWORD 'ton_mot_de_passe';
```

Droits:
```sql
ALTER USER tyaouser CREATEDB;
```

Quitte PostgreSQL :
```sql
\q
```

12. Créer la base de données
```bash
sudo -u postgres createdb -O tyaouser nom_de_ta_base
```

## Installer le client PostgreSQL dans ton projet Django
```bash
pip install psycopg2-binary
```

## Configurer Django pour utiliser PostgreSQL
```python
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': 'django_db',        # Le nom de ta base
        'USER': 'tyaouser',         # L'utilisateur PostgreSQL
        'PASSWORD': 'ton_mot_de_passe',
        'HOST': 'localhost',        # ou l’IP du serveur
        'PORT': '5432',             # port postgres par défaut
    }
}
```

## Tester la connexion Django → PostgreSQL
Lance les migrations :
```bash
python manage.py migrate
```

Si tu vois :
```nginx
Applying auth.0001_initial... OK
```

🎉 La connexion fonctionne !