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
git pull origin $CURRENT_BRANCH
echo "ℹ️ Installing composer dependencies..."
composer install --no-interaction --prefer-dist --optimize-autoloader --no-dev


# ============================
# MIGRAÇÕES E OTIMIZAÇÕES
# ============================
echo "ℹ️ Running database migrations and optimizations..."
php artisan migrate --force
php artisan dothnews:sync-permissions
php artisan clear-compiled
php artisan optimize # talvez isso de pau nas rotas

echo "ℹ️ Generating application version info..."
php artisan about

# Gera arquivo com informações do último commit
echo "ℹ️ Writing version info to public/version.txt..."
git log -1 --pretty="Branch: $CURRENT_BRANCH%nAutor: %an%nData: %ad%nMensagem:%n%B" > public/version.txt


# ============================
# CONFIGURAÇÃO DO NPM (USER-ONLY) e INSTALAÇÃO DE DEPENDÊNCIAS
# ============================
cd /home/$USER/$DOMAIN/resources/$THEME_DIR/

npm config set cache ~/.npm
mkdir -p ~/.npm-global/bin
npm config set prefix ~/.npm-global
export PATH="$HOME/.npm-global/bin:$PATH"

rm -rf node_modules
# instala dependências exatas do package-lock.json
echo "ℹ️ Installing npm dependencies from theme..."
npm ci

# ============================
# BUILD DE PRODUÇÃO
# ============================
echo "ℹ️ Building theme for production..."
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
cd /home/$USER/$DOMAIN
echo "ℹ️ Horizon terminating..."
php artisan horizon:terminate
echo "🚀 Application deployed!"