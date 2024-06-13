healthy_keycloak=`docker inspect --format "{{.State.Health.Status}}" $(docker compose ps -q keycloak)`
healthy_shinyproxy=`docker inspect --format "{{.State.Health.Status}}" $(docker compose ps -q shinyproxy)`
echo $healthy_keycloak
echo $healthy_shinyproxy
