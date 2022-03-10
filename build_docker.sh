#!/bin/bash
#
# On Windows WSL2, do not run it when RStudio is active
# See https://stackoverflow.com/a/66715570/229794
# Make this file executable after copying it from Windows
# Renviron must be saved with UNIX file endings
# The following line can be commented out when there is no Windows-LF risk
# Use it whenever you see a <^M> turn up in error message
#dos2unix ./inst/Renviron_devel
export R_CONFIG_ACTIVE=sa_admin
set -o allexport;
source ./inst/Renviron_devel
set +o allexport

export DOCKER_ANOMANOR_STANDALONE=TRUE
echo "Active configuration: $R_CONFIG_ACTIVE DOCKER_ANOMANOR_STANDALONE=$DOCKER_ANOMANOR_STANDALONE"

docker rm -f anomanor
# To force rebuild
#docker rmi -f anomanor
docker system prune -f
docker build --tag dmenne/anomanor -f Dockerfile_anomanor \
  --build-arg R_CONFIG_ACTIVE \
  --build-arg ANOMANOR_DATA \
  --build-arg ANOMANOR_ADMIN_USERNAME \
  --build-arg ANOMANOR_ADMIN_PASSWORD \
  --build-arg DOCKER_ANOMANOR_STANDALONE \
  .

# https://github.com/moby/moby/issues/25245#issuecomment-365970076
docker container create --name copydata -v anomanor_data_data:/root hello-world
docker cp ./inst/data_store/records copydata:/root/records
docker cp ./inst/data_store/patients copydata:/root/patients
docker cp ./inst/data_store/md copydata:/root/md
docker rm copydata

docker run -d -it  \
  --name anomanor \
  --restart unless-stopped \
  --publish 3838:3838 \
  -v anomanor_data_db:${ANOMANOR_DATA}/db \
  -v anomanor_data_cache:${ANOMANOR_DATA}/cache \
  -v anomanor_data_data:${ANOMANOR_DATA}/data \
  dmenne/anomanor

docker ps -l
sleep 3s
docker logs anomanor

echo "Connect with your browser at localhost:3838"
