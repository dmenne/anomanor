rscript -e "rhub::check_on_linux()" >check_rhub.log
ECHO "Window will be closed after 5 seconds"
@PING -n 5 127.0.0.1>nul 
