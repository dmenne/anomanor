docker compose down
docker rmi -f anomanor_shiny-shinyproxy
docker compose up --build --force-recreate --remove-orphans -d