#!/usr/bin/env bash
set -Eeuo pipefail

# V3 - Elimina a necessidade de passar variaveis user e donain
# Ex
# curl -sSL https://raw.githubusercontent.com/onovaes/dndeploi/main/admin/deploy_to_prod_v3.sh | bash -s "{SITE_DIRECTORY}" "{SITE_DOMAIN}" "{BRANCH}"

# ============================
# VARIÁVEIS DE CONFIGURAÇÃO
# ============================
SITE_DIRECTORY=$1
DOMAIN=$2
CURRENT_BRANCH=$3

# ============================
# INFOS PARA DEBUG
# ============================
echo "📁 Site Directory: $SITE_DIRECTORY"
echo "🌐 Domain: $DOMAIN"
echo "🌿 Current Branch: $CURRENT_BRANCH"


# ============================
# Atualiza REPOSITÓRIO e INSTALA DEPENDÊNCIAS
# ============================
cd $SITE_DIRECTORY
echo "🍀 Checked out branch: $CURRENT_BRANCH"
git pull origin $CURRENT_BRANCH
git fetch --tags
echo "ℹ️ Installing admin application with composer dependencies ..."
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