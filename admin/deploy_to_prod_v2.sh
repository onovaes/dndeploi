#!/usr/bin/env bash
set -Eeuo pipefail

# V2 - Melhora limpeza de cache

# ---------------------------------------------
# This script will be run after deploy in prod (Without staging) has been run
# ---------------------------------------------

# ============================
# VARIÁVEIS DE CONFIGURAÇÃO
# ============================
USER=$1
DOMAIN=$2
CURRENT_BRANCH=$3

# ============================
# Atualiza REPOSITÓRIO e INSTALA DEPENDÊNCIAS
# ============================
cd /home/$USER/$DOMAIN
echo "🍀 Checked out branch: $CURRENT_BRANCH"
git pull origin $CURRENT_BRANCH

echo "ℹ️ Installing admin application composer dependencies ..."
composer install --no-interaction --prefer-dist --optimize-autoloader --no-dev


# ============================
# Npm CONFIG E INSTALA DEPENDÊNCIAS GLOBAIS
# ============================
echo "ℹ️ Installing dependencies and building assets for admin application..."
npm ci
npm run build

# ============================
# Artisan optimize e livewire publish assets
# ============================
echo "ℹ️ Running artisan commands..."
php artisan optimize:clear

php artisan config:cache
php artisan route:cache
php artisan view:cache
php artisan event:cache

php artisan livewire:publish --assets

# Gera arquivo com informações do último commit
echo "ℹ️ Writing version info to public/version.txt..."
git log -1 --pretty="Branch: $CURRENT_BRANCH%nAutor: %an%nData: %ad%nMensagem:%n%B" > public/version.txt


# ============================
# RELOAD PHP-FPM
# ============================
echo "ℹ️ Reloading PHP-FPM service..."
echo "" | sudo -S service php8.4-fpm reload

echo "🚀 SUCCESS! Admin Application deployed!"