#!/bin/bash
# Windows wsl
# sudo chown ${USER}:docker /home/dieter/keycloak/data
#Permission denied in shinyproxy:
#https://stackoverflow.com/questions/64099538/shinyproxy-error-500-failed-to-start-container-caused-by-java-io-ioexceptio
# sudo usermod -aG docker $USER
# Must be run after each server reboot
#sudo chown $USER:docker /var/run/docker.sock
source ./chown_docker_sock.sh

set -o allexport;
source ./.Renviron
if [[ "$R_CONFIG_ACTIVE" = "keycloak_production" ]]
then
  source ./inst/Renviron_production
else
  source ./inst/Renviron_devel
fi
set +o allexport
#echo $KEYCLOAK_IP
if [[ "$R_CONFIG_ACTIVE" != *"keycloak"* ]]
then
  echo "R_CONFIG_ACTIVE is set to ${R_CONFIG_ACTIVE} in .Renviron"
  echo "You must use keycloak_devel or keycloak_production"
  exit 1
fi

docker-compose down
docker system prune -f
#docker network rm anomanor-net

# https://github.com/moby/moby/issues/25245
# These 3 lines can be removed when nothing has changed in /data_store
docker container create --name copydata -v anomanor_data:/root hello-world
# Next line copies test data. Comment it to avoid this for production
# docker cp ./inst/data_store/. copydata:/root
# md-data are always copied
docker cp ./inst/data_store/md copydata:/root/md
docker rm copydata

docker rm -f anomanor
#docker rmi -f anomanor
docker build  --tag anomanor -f Dockerfile_anomanor \
  --build-arg R_CONFIG_ACTIVE\
  --build-arg ANOMANOR_DATA \
  --build-arg ANOMANOR_ADMIN_USERNAME\
  --build-arg ANOMANOR_ADMIN_PASSWORD \
  .

# Use this when application.yml has changed
# docker rmi -f  anomanor_shiny_shinyproxy

docker-compose up --build -d
#docker-compose up --build -d traefik shinyproxy keycloak

#docker network inspect -f '{{json .Containers}}' anomanor-net | jq '.[] | .Name + ":" + .IPv4Address'
#docker logs keycloak --follow
#docker logs shinyproxy --follow
#docker logs traefik --follow
