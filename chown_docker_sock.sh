#/bin/bash

own_file() {
	if [[ -e $1 ]]
	  then
      us=$(stat -c "%U" $1)
      gr=$(stat -c "%G" $1)
      if [[ $us != ${USER} || $gr != "docker" ]]
      then
        sudo chmod ${2:-660} $1
        sudo chown ${USER}:docker $1
        us=$(stat -c "%U" $1)
        gr=$(stat -c "%G" $1)
        echo "Changed owner for   $1 to $us:$gr"
      fi
	fi
}

own_file "/var/run/docker.sock"
own_file "/home/hrmconsensus/anomanor_data/anomanor/db"
# acme must be 600
own_file "./letsencrypt/acme.json" 600
