#!/usr/bin/env bash
set -Eeuo pipefail

# Diferencas em relacao ao v1
# - Aceita trocar de branch, recebendo no parametro 4 o nome da branch atual
# - Suporte a php artisan horizon:terminate no final do deploy
# - Uma série de melhorias de infos com ℹ️ e 🚀 para melhor visualização do progresso do deploy
# - O 3º parâmetro agora é o caminho absoluto do theme (THEME_PATH).
#   resources/<basename(THEME_PATH)> vira symlink para THEME_PATH.
#   Build (npm ci + make build-prod) e permissões do theme saem deste script
#   e passam a ser responsabilidade externa.

# ---------------------------------------------
# This script will be run after deploy in prod (Without staging) has been run
# ---------------------------------------------

# ============================
# VARIÁVEIS DE CONFIGURAÇÃO
# ============================
SITE_DIRECTORY=$1
DOMAIN=$2
THEME_PATH=$3
CURRENT_BRANCH=$4

THEME_DIR="$(basename "$THEME_PATH")"
RESOURCES_THEME_PATH="$SITE_DIRECTORY/resources/$THEME_DIR"

# ============================
# INSTALAÇÃO DO TEMA (symlink)
# ============================
if [ ! -e "$THEME_PATH" ]; then
    echo "❌ THEME_PATH '$THEME_PATH' não existe. Abortando."
    exit 1
fi

if [ -L "$RESOURCES_THEME_PATH" ] || [ -e "$RESOURCES_THEME_PATH" ]; then
    echo "ℹ️ $RESOURCES_THEME_PATH já existe — pulando criação do symlink."
else
    echo "ℹ️ Creating symlink $RESOURCES_THEME_PATH -> $THEME_PATH ..."
    ln -s "$THEME_PATH" "$RESOURCES_THEME_PATH"
fi


# ============================
# DEPLOY DA APLICAÇÃO
# ============================
echo "🍀 Checked out branch: $CURRENT_BRANCH"
cd "$SITE_DIRECTORY"
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
# RELOAD PHP E FINALIZAÇÃO
# ============================
echo "" | sudo -S service php8.4-fpm reload
cd "$SITE_DIRECTORY"
echo "ℹ️ Horizon terminating..."
php artisan horizon:terminate
echo "🚀 SUCCESS! Application deployed!"