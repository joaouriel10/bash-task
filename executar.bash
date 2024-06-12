#!/bin/bash

# Verifica se o arquivo repos.txt existe
if [ ! -f repos.txt ]; then
    echo "O arquivo repos.txt não foi encontrado!"
    exit 1
fi

# Cria um diretório para os projetos
mkdir -p projetos
cd projetos

# Lê cada URL do repos.txt e clona o repositório
while IFS= read -r repo; do
    # Extrai o nome do projeto a partir do URL
    project_name=$(basename -s .git "$repo")

    # Clona o repositório
    git clone "$repo"
    if [ $? -ne 0 ]; then
        echo "Falha ao clonar $repo"
        continue
    fi

    cd "$project_name" || continue

    pnpm i

    echo "$project_name"
    # Cria arquivo .env com base no .env.example se o projeto for api-tasks ou api-users
    if [[ "$project_name" == "api-tasks" || "$project_name" == "api-users" || "$project_name" == "api-logs" ]]; then
        if [ -f .env.example ]; then
            echo "Criando arquivo .env para $project_name baseado no .env.example"
            cp .env.example .env
        else
            echo "Arquivo .env.example não encontrado em $project_name"
        fi
    fi

    # Executa docker compose up -d se o projeto for api-tasks, api-logs ou api-users
    if [[ "$project_name" == "api-tasks" || "$project_name" == "api-logs" || "$project_name" == "api-users" ]]; then
        if [ -f docker-compose.yml ]; then
            echo "Rodando docker compose up -d para $project_name"
            docker compose up -d --force-recreate
            sleep 3
        else
            echo "Arquivo docker-compose.yml não encontrado em $project_name"
        fi
    fi

    # Executa os comandos pnpm prisma db push e pnpm prisma generate se o projeto for api-tasks ou api-users
    if [[ "$project_name" == "api-tasks" || "$project_name" == "api-users" ]]; then
        if command -v pnpm &> /dev/null; then
            echo "Executando pnpm prisma db push para $project_name"
            pnpm prisma db push
            echo "Executando pnpm prisma generate para $project_name"
            pnpm prisma generate
        else
            echo "pnpm não está instalado. Por favor, instale pnpm para continuar."
        fi
    fi

    # Inicia o projeto em um novo terminal com pnpm start:dev ou pnpm dev para api-tasks
    if command -v terminator &> /dev/null; then
        echo "Iniciando $project_name com pnpm dev em um novo terminal"
        sleep 1
        if [[ "$project_name" == "api-tasks" ]]; then
            terminator -e "cd $(pwd) && pnpm dev" &
        else
            echo "Iniciando $project_name com pnpm start:dev em um novo terminal"
            terminator -e "cd $(pwd) && pnpm start:dev" &
        fi
    else
        echo "terminator não está instalado. Por favor, instale terminator para continuar."
    fi

    # Volta para o diretório pai
    cd ..
done < ../repos.txt

echo "Todos os projetos foram clonados e configurados!"