#!/bin/bash
# Windows wsl
# sudo chown ${USER}:docker /home/dieter/keycloak/data
#Permission denied in shinyproxy:
#https://stackoverflow.com/questions/64099538/shinyproxy-error-500-failed-to-start-container-caused-by-java-io-ioexceptio
# sudo usermod -aG docker $USER
# Must be run after each server reboot
#sudo chown $USER:docker /var/run/docker.sock

# https://vaneyckt.io/posts/safer_bash_scripts_with_set_euxo_pipefail/
set -euxo pipefail

source ./chown_docker_sock.sh
dos2unix ./.Renviron

# Make sure that ./.Renviron is valid
set -a
source <(cat ./.Renviron | sed -e '/^#/d;/^\s*$/d' -e "s/'/'\\\''/g" -e "s/=\(.*\)/='\1'/g")
set +a


if [[ $R_CONFIG_ACTIVE != *"keycloak"* ]];
then
  echo "R_CONFIG_ACTIVE is set to ${R_CONFIG_ACTIVE} in .Renviron"
  echo "You must use keycloak_devel or keycloak_production"
  exit 1
fi

echo $R_CONFIG_ACTIVE

if [[ $R_CONFIG_ACTIVE = "keycloak_production" ]]; then
  ln -sf ./inst/Renviron_production ./.env
  echo "Read <<./inst/Renviron_production>>"
else
  ln -sf ./inst/Renviron_devel ./.env
fi

set -a
source <(cat ./.env | sed -e '/^#/d;/^\s*$/d' -e "s/'/'\\\''/g" -e "s/=\(.*\)/='\1'/g")
set +a

if [ -z "$ANOMANOR_SECRET" ]; then
  echo "ANOMANOR_SECRET is empty"
  exit 1
fi


docker compose down
docker system prune -f
#docker network rm anomanor-net


docker rm -f anomanor
#docker rmi -f anomanor

docker build  --tag anomanor -f Dockerfile_anomanor \
  --build-arg R_CONFIG_ACTIVE \
  --build-arg ANOMANOR_DATA \
  --build-arg ANOMANOR_ADMIN_USERNAME\
  --build-arg ANOMANOR_ADMIN_PASSWORD \
  .


# Thanks, chatgpt. (not tested)
# Get the last modification time of application.yml
app_mod_time=$(stat -c %Y application.yml)

if docker inspect anomanor_shiny-shinyproxy >/dev/null 2>&1
then
  # Get the creation time of the Docker image
  image_build_time=$(docker inspect --format='{{.Created}}' anomanor_shiny-shinyproxy | xargs date +%s -d)

  # Compare the times and remove the image if application.yml is newer
  if [ $app_mod_time -gt $image_build_time ]
  then
      docker rmi -f anomanor_shiny-shinyproxy
  fi
fi

docker compose up --build -d
#docker compose up --build -d traefik shinyproxy keycloak

#docker network inspect -f '{{json .Containers}}' anomanor-net | jq '.[] | .Name + ":" + .IPv4Address'
#docker logs keycloak --follow
#docker logs shinyproxy --follow
#docker logs traefik --follow
