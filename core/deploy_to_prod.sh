#!/usr/bin/env bash
set -Eeuo pipefail

# ---------------------------------------------
# This script will be run after deploy in prod (Without staging) has been run
# ---------------------------------------------

# ============================
# VARIÁVEIS DE CONFIGURAÇÃO
# ============================
USER=$1
DOMAIN=$2
THEME_DIR=$3

# ============================
# DEPLOY DA APLICAÇÃO
# ============================
cd /home/$USER/$DOMAIN

git pull origin main
composer install --no-interaction --prefer-dist --optimize-autoloader --no-dev

# ============================
# MIGRAÇÕES E OTIMIZAÇÕES
# ============================
php artisan migrate --force
php artisan dothnews:sync-permissions
php artisan clear-compiled
php artisan optimize # talvez isso de pau nas rotas
php artisan about

# Gera arquivo com informações do último commit
git log -1 --pretty="Autor: %an%nData: %ad%nMensagem:%n%B" > public/dnversion.txt

# ============================
# INSTALAÇÃO DO TEMA
# ============================
rm -rf /home/$USER/$DOMAIN/resources/$THEME_DIR
mkdir -p /home/$USER/$DOMAIN/resources
cp -R /home/themes/$THEME_DIR/. /home/$USER/$DOMAIN/resources/$THEME_DIR/

cd /home/$USER/$DOMAIN/resources/$THEME_DIR/

# ============================
# CONFIGURAÇÃO DO NPM (USER-ONLY)
# ============================
npm config set cache ~/.npm
mkdir -p ~/.npm-global/bin
npm config set prefix ~/.npm-global
export PATH="$HOME/.npm-global/bin:$PATH"

rm -rf node_modules
# instala dependências exatas do package-lock.json
npm ci

# ============================
# BUILD DE PRODUÇÃO
# ============================
make build-prod

# ============================
# PERMISSÕES
# ============================
find . -path './.git' -prune -o -path './node_modules' -prune -o -type d -exec chmod 755 {} \;
find . -path './.git' -prune -o -path './node_modules' -prune -o -type f -exec chmod 644 {} \;

# ============================
# RELOAD PHP E FINALIZAÇÃO
# ============================
echo "" | sudo -S service php8.4-fpm reload
echo "🚀 Application deployed!"