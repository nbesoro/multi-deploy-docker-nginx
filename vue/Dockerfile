# Étape de build
FROM node:20-alpine AS builder

WORKDIR /app

# Installer les dépendances système nécessaires pour certains packages npm
RUN apk add --no-cache python3 make g++

# Copier les fichiers de dépendances
COPY package*.json ./

# IMPORTANT: Installer TOUTES les dépendances (pas seulement production)
# Car on a besoin des devDependencies pour le build
RUN npm install

# Copier le code source
COPY . .

# Build avec l'URL de production
ARG VITE_API_BASE_URL=https://goals-api.nbesoro.com
ENV VITE_API_BASE_URL=$VITE_API_BASE_URL

# Build de production
RUN npm run build

# Étape de production - nginx léger
FROM nginx:alpine

# Copier les fichiers buildés depuis l'étape builder
COPY --from=builder /app/dist /usr/share/nginx/html

# Configuration nginx pour Vue Router
RUN echo 'server { \
    listen 80; \
    server_name localhost; \
    root /usr/share/nginx/html; \
    index index.html; \
    location / { \
        try_files $uri $uri/ /index.html; \
    } \
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ { \
        expires 1y; \
        add_header Cache-Control "public, immutable"; \
    } \
}' > /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]