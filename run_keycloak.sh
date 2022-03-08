#!/bin/bash
docker-compose -f docker-compose_keycloak.yml down --remove-orphans
docker-compose -f docker-compose_keycloak.yml up -d
echo "---- Use localhost:8010 - startup needs almost a minute, be patient ---"
