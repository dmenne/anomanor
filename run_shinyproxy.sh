#!/bin/bash
bash ./chown_docker_sock.sh

# echo "Set authentication: simple (instead of keycloak) in  application.yml"
set -o allexport;
source ./.Renviron
if [[ "$R_CONFIG_ACTIVE" = "keycloak_production" ]]
then
  ln -sf ./inst/Renviron_production ./.env
  source ./inst/Renviron_production
else
  ln -sf ./inst/Renviron_devel ./.env
  source ./inst/Renviron_devel
fi
set +o allexport

if [[ "$R_CONFIG_ACTIVE" == *"keycloak"* ]]
then
  echo "R_CONFIG_ACTIVE is set to ${R_CONFIG_ACTIVE} in .Renviron"
  echo "You cannot use R_CONFIG_ACTIVE with keycloak in this script"
  exit 1
fi

#docker compose down --remove-orphans
docker compose down
#docker rm -f anomanor
docker build  --tag anomanor -f Dockerfile_anomanor \
  --build-arg R_CONFIG_ACTIVE \
  --build-arg ANOMANOR_DATA \
  --build-arg ANOMANOR_ADMIN_USERNAME \
  --build-arg ANOMANOR_ADMIN_PASSWORD \
  .

# must uncomment this when application.yml has changed
#docker rmi -f shinyproxy
docker-compose up -d shinyproxy
docker logs shinyproxy --follow
