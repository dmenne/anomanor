#!/bin/bash
#
# On Windows, do not run it when RStudio is active
# See https://stackoverflow.com/a/66715570/229794
# Make this file executable after copying it from Windows
# Renviron must be saved with UNIX file endings
# The following line can be commented out when there is no Windows-LF risk
# Use it whenever you see a <^M> turn up in error message
#dos2unix ./inst/Renviron_devel

# https://vaneyckt.io/posts/safer_bash_scripts_with_set_euxo_pipefail/
set -euxo pipefail

set -o allexport;
source ./.Renviron
source ./inst/Renviron_devel
set +o allexport

if [[ "$R_CONFIG_ACTIVE" == *"keycloak"* ]]
then
  echo "R_CONFIG_ACTIVE is set to ${R_CONFIG_ACTIVE} in .Renviron"
  echo "You cannot use R_CONFIG_ACTIVE with keycloak in this script"
  exit 1
fi

export DOCKER_ANOMANOR_STANDALONE=TRUE
echo "Active configuration: $R_CONFIG_ACTIVE DOCKER_ANOMANOR_STANDALONE=$DOCKER_ANOMANOR_STANDALONE"

TAG=$(awk -v RS='\r\n' '/^Version/ {print $2}' DESCRIPTION)
echo Version from DESCRIPTION: ${TAG}

docker rm -f anomanor
# To force rebuild
#docker rmi -f anomanor
#docker system prune -f
docker build -f Dockerfile_anomanor \
  --tag dmenne/anomanor:${TAG} \
  --build-arg R_CONFIG_ACTIVE \
  --build-arg ANOMANOR_DATA \
  --build-arg ANOMANOR_ADMIN_USERNAME \
  --build-arg ANOMANOR_ADMIN_PASSWORD \
  --build-arg DOCKER_ANOMANOR_STANDALONE \
  .

docker run -d -it  \
  --name anomanor \
  --restart unless-stopped \
  --publish 4848:3838 \
  -v anomanor_data_db:${ANOMANOR_DATA}/db \
  -v anomanor_data_cache:${ANOMANOR_DATA}/cache \
  -v anomanor_data_data:${ANOMANOR_DATA}/data \
  dmenne/anomanor:${TAG}

docker ps -l
sleep 3s
docker logs anomanor
#docker exec -it anomanor curl localhost:3838 | head
# https://stackoverflow.com/a/28879552/229794
# curl localhost:4848 | tac | tac | head
echo "------ Connect via localhost:4848 -------"
