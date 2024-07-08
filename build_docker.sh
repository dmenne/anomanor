#!/bin/bash
#
# On Windows WSL2, do not run it when RStudio is active
# See https://stackoverflow.com/a/66715570/229794
# Make this file executable after copying it from Windows
# Renviron must be saved with UNIX file endings
#
# The following line can be commented out when there is no Windows-LF risk
# Use it whenever you see a <^M> or <<$'\r': command not found>> turn up in error message
# use <<sudo install dos2unix>> to install
#dos2unix ./inst/Renviron_devel
export R_CONFIG_ACTIVE=sa_admin # or sa_expert, sa_trainee
set -o allexport;
source ./inst/Renviron_devel
set +o allexport

export DOCKER_ANOMANOR_STANDALONE=TRUE
echo "Active configuration: $R_CONFIG_ACTIVE DOCKER_ANOMANOR_STANDALONE=$DOCKER_ANOMANOR_STANDALONE"
TAG="1.0.1"

docker rm -f anomanor
# To force rebuild
#docker rmi -f anomanor
docker system prune -f
docker build -f Dockerfile_anomanor \
  --tag dmenne/anomanor:${TAG} \
  --build-arg R_CONFIG_ACTIVE \
  --build-arg ANOMANOR_DATA \
  --build-arg ANOMANOR_ADMIN_USERNAME \
  --build-arg ANOMANOR_ADMIN_PASSWORD \
  --build-arg DOCKER_ANOMANOR_STANDALONE \
  .

docker push dmenne/anomanor:${TAG}


# When run under Windows/wsl2, volumes can be found here:
# \\wsl.localhost\docker-desktop-data\data\docker\volumes
# Example:
# ls '\\wsl.localhost\docker-desktop-data\data\docker\volumes\anomanor_data_db\_data\anomanor.sqlite'
# From Windows: Enter \\wsl$ into Explorer

docker run -d -it  \
  --name anomanor \
  --restart unless-stopped \
  --publish 3838:3838 \
  -v anomanor_data_db:${ANOMANOR_DATA}/db \
  -v anomanor_data_cache:${ANOMANOR_DATA}/cache \
  -v anomanor_data_data:${ANOMANOR_DATA}/data \
  dmenne/anomanor:${TAG}

docker ps -l
sleep 3s
docker logs anomanor

echo "Connect with your browser at localhost:3838"
