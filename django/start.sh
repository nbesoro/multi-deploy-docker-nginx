#!/bin/bash

# Script de démarrage
set -e

echo "🚀 Démarrage de Daily Goals Backend..."

# Wait for remote database connection (if using PostgreSQL)
if [[ "$DATABASE_URL" =~ ^postgresql:// ]]; then
    echo "⏳ Attente de la connexion à la base de données distante..."
    
    python -c "
import sys
import time
import os
import django
from django.db import connections
from django.db.utils import OperationalError

# Configure Django settings
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

db_available = False
attempts = 0
max_attempts = 30

while not db_available and attempts < max_attempts:
    try:
        db_conn = connections['default']
        with db_conn.cursor() as cursor:
            cursor.execute('SELECT 1')
        db_available = True
        print('✅ Base de données distante prête!')
    except OperationalError:
        attempts += 1
        print(f'❌ DB indisponible, attente... ({attempts}/{max_attempts})')
        time.sleep(2)

if not db_available:
    print('❌ Impossible de se connecter à la DB après 30 tentatives')
    sys.exit(1)
"
else
    echo "📁 Utilisation de SQLite"
fi

# Run migrations
echo "📦 Exécution des migrations..."
# python manage.py makemigrations --noinput || true
python manage.py migrate --noinput

# Collect static files
echo "📁 Collection des fichiers statiques..."
# python manage.py collectstatic --noinput --clear

# Create superuser in development mode only
if [ "$DEBUG" = "True" ] || [ "$DEBUG" = "1" ]; then
    echo "👤 Création du superuser si nécessaire..."
    python manage.py shell -c "
from django.contrib.auth import get_user_model
User = get_user_model()
if not User.objects.filter(username='admin').exists():
    User.objects.create_superuser('admin', 'admin@example.com', 'admin123')
    print('✅ Superuser créé: admin/admin123')
else:
    print('ℹ️ Superuser existe déjà')
" || echo "⚠️ Impossible de créer le superuser"
fi

# Load initial data if available
if [ -f "fixtures/initial_data.json" ]; then
    echo "📊 Chargement des données initiales..."
    python manage.py loaddata fixtures/initial_data.json || echo "⚠️ Impossible de charger les données initiales"
fi


echo "✅ Setup terminé!"

# Choose server based on environment
if [ "$DEBUG" = "True" ] || [ "$DEBUG" = "1" ]; then
    echo "🌐 Démarrage du serveur de développement Django sur le port 8010..."
    exec python manage.py runserver 0.0.0.0:8001
else
    echo "🌐 Démarrage du serveur Gunicorn (production) sur le port 8010..."
    exec gunicorn --bind 0.0.0.0:8010 --workers 3 --timeout 120 --keep-alive 5 --max-requests 1000 --max-requests-jitter 50 core.wsgi:application
fi