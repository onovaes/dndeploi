# dndeploi

A simples scripts de deploy para aplicações PHP/Laravel hospedadas no Ploi.io

## Exemplo de uso do script de deploy para produção 

# ============================
# CONFIGURAÇÃO
# ============================
USER="meu-usuario"
DOMAIN="meu dominio.com.br"

curl -fsSL https://raw.githubusercontent.com/onovaes/dndeploi/main/core/sync_to_prod.sh | bash -s "$USER" "$DOMAIN"

