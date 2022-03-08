:: Assumes Docker Desktop for Windows is installed
:: https://docs.docker.com/desktop/windows/install/
:: This batch file starts anomanor on your local computer
docker run -d -it --name anomanor ^
  --restart unless-stopped ^
  --publish 3838:3838 ^
  -v anomanor_data_db:${ANOMANOR_DATA}/db ^
  -v anomanor_data_cache:${ANOMANOR_DATA}/cache ^
  -v anomanor_data_data:${ANOMANOR_DATA}/data ^
  dmenne/anomanor:latest

docker ps -l
sleep 3s
docker logs anomanor

echo "Connect with your browser at localhost:3838"
