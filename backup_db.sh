#!/bin/bash
# Backup PostgreSQL database for Keycloak
# https://vaneyckt.io/posts/safer_bash_scripts_with_set_euxo_pipefail/
set -x
set -euxo pipefail

export PATH=/usr/local/bin:/usr/local/sbin:/bin:/sbin:/usr/bin:/usr/sbin

service_name=postgres
database_name=keycloak
date=$(date +%Y-%m-%d"_"%H_%M_%S)
backup_filename="${database_name}_${date}.sql"
backup_filename_zipped="${backup_filename}.gz"

docker_bin=$(which docker)

container_id=$(docker ps | grep $service_name | awk '{print $1}')

# create the backup
$docker_bin exec $container_id pg_dump -U anomanor_admin -f /tmp/$backup_filename $database_name

# copy file inside contaienr to host
$docker_bin cp $container_id:/tmp/$backup_filename .

# remove file in container
$docker_bin exec $container_id rm /tmp/$backup_filename

# compress
gzip $backup_filename

# move to destination
mv "${backup_filename}.gz" ~/anomanor_shiny/keycloak

rsync -r -u --ignore-errors ~/anomanor_data/anomanor/data ~/anomanor_data/backup

echo "Done."
