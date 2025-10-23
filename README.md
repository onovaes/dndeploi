# dndeploi

A simples scripts de deploy para aplicações PHP/Laravel hospedadas no Ploi.io

## Exemplo de uso do script de deploy para produção 

# ============================
# CONFIGURAÇÃO
# ============================
USER="meu-usuario"
DOMAIN="meu dominio.com.br"

curl -fsSL https://raw.githubusercontent.com/onovaes/dndeploi/main/core/deploy_to_prod.sh -o /tmp/deploy_to_prod.sh
chmod +x /tmp/deploy_to_prod.sh
/tmp/deploy_to_prod.sh $USER $DOMAIN

