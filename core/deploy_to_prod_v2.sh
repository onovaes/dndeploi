#!/usr/bin/env bash
set -Eeuo pipefail

# Diferencas em relacao ao v1
# - Aceita trocar de branch, recebendo no parametro 4 o nome da branch atual
# - Suporte a php artisan horizon:terminate no final do deploy
# - Uma série de melhorias de infos com ℹ️ e 🚀 para melhor visualização do progresso do deploy

# ---------------------------------------------
# This script will be run after deploy in prod (Without staging) has been run
# ---------------------------------------------

# ============================
# VARIÁVEIS DE CONFIGURAÇÃO
# ============================
USER=$1
DOMAIN=$2
THEME_DIR=$3
CURRENT_BRANCH=$4

# ============================
# INSTALAÇÃO DO TEMA
# ============================
echo "ℹ️ Rsyncing theme files from /home/themes/$THEME_DIR/ to /home/$USER/$DOMAIN/resources/$THEME_DIR/ ..."
rsync -a --delete /home/themes/$THEME_DIR/ /home/$USER/$DOMAIN/resources/$THEME_DIR/


# ============================
# DEPLOY DA APLICAÇÃO
# ============================
echo "🍀 Checked out branch: $CURRENT_BRANCH"
cd /home/$USER/$DOMAIN
git fetch origin $CURRENT_BRANCH
git fetch --tags
git reset --hard origin/$CURRENT_BRANCH
echo "ℹ️ Installing dothnews-core composer dependencies ..."
composer install --no-interaction --prefer-dist --optimize-autoloader --no-dev


# ============================
# MIGRAÇÕES E OTIMIZAÇÕES
# ============================
echo "ℹ️ Running database migrations and optimizations..."
php artisan migrate --force

echo "ℹ️ Syncing permissions..."
php artisan dothnews:sync-permissions

echo "ℹ️ Caching configuration with artisan clear-compiled..."
php artisan clear-compiled

echo "ℹ️ Optimizing application with artisan optimize..."
php artisan optimize # talvez isso de pau nas rotas

echo "ℹ️ Generating application version info..."
php artisan about

# Gera arquivo com informações do último commit
echo "ℹ️ Writing version info to public/version.txt..."
git log -1 --pretty="Branch: $CURRENT_BRANCH%nAutor: %an%nData: %ad" > public/version.txt
echo "Tag: $(git describe --tags --abbrev=0)" >> public/version.txt


# ============================
# CONFIGURAÇÃO DO NPM (USER-ONLY) e INSTALAÇÃO DE DEPENDÊNCIAS
# ============================
echo "ℹ️ Setting up npm for user $USER and installing theme dependencies..."
cd /home/$USER/$DOMAIN/resources/$THEME_DIR/

npm config set cache ~/.npm
mkdir -p ~/.npm-global/bin
npm config set prefix ~/.npm-global
export PATH="$HOME/.npm-global/bin:$PATH"

rm -rf node_modules
echo "ℹ️ Installing npm dependencies from package-lock.json..."
npm ci

# ============================
# BUILD DE PRODUÇÃO
# ============================
echo "ℹ️ Building theme for production..."
make build-prod

# ============================
# PERMISSÕES
# ============================
echo "ℹ️ Setting file and directory permissions..."
find . -path './.git' -prune -o -path './node_modules' -prune -o -type d -exec chmod 755 {} \;
find . -path './.git' -prune -o -path './node_modules' -prune -o -type f -exec chmod 644 {} \;

# ============================
# RELOAD PHP E FINALIZAÇÃO
# ============================
echo "" | sudo -S service php8.4-fpm reload
cd /home/$USER/$DOMAIN
echo "ℹ️ Horizon terminating..."
php artisan horizon:terminate
echo "🚀 SUCCESS! Application deployed!"