#!/usr/bin/env bash
set -Eeuo pipefail


# ---------------------------------------------
# This script will be run after staging to production deployment has been run
# ---------------------------------------------

# Variables
USER=$1
FOLDER=$2

cd /home/$USER/$FOLDER || exit 1

php artisan storage:link --force
php artisan migrate --force
php artisan dothnews:sync-permissions

php artisan optimize:clear
php artisan optimize # talvez isso de pau nas rotas

php artisan about

echo "" | sudo -S service php8.4-fpm reload
echo "🚀 Application deployed!"