# Dn Deploi - Deploy Scripts for Ploi.io

Scripts de deploy para aplicações PHP/Laravel hospedadas no Ploi.io

## Exemplo de uso do script de deploy para staging

    # Configure as variáveis abaixo
    USER="meu-usuario"
    DOMAIN="staging.meudominio.com.br"
    THEME_DIR="my_first_blog"

    curl -fsSL https://raw.githubusercontent.com/onovaes/dndeploi/main/core/deploy_to_staging.sh | bash -s "$USER" "$DOMAIN" "$THEME_DIR"

## Exemplo de uso do script de sync para produção 

    # Configure as variáveis abaixo
    USER="meu-usuario"
    DOMAIN="meudominio.com.br"

    curl -fsSL https://raw.githubusercontent.com/onovaes/dndeploi/main/core/sync_to_prod.sh | bash -s "$USER" "$DOMAIN"
