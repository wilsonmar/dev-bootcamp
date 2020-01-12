#!/usr/bin/env bash

# run-flask.sh in https://github.com/wilsonmar/dev-bootcamp
# This makes use of postgres docker image instantiated by install.sh.

# After getting into the Cloud9 enviornment,
# cd to folder, copy this line and paste in the Cloud9 terminal:
# bash -c "$(curl -fsSL https://raw.githubusercontent.com/wilsonmar/dev-bootcamp/master/run-flask.sh)"

# This was tested on macOS Mojave and Amazon Linux 2018.2 in EC2.



### STEP 1. Set display utilities:

#clear  # screen (but not history)

set -e  # to end if 
# set -eu pipefail  # pipefail counts as a parameter
# set -x to show commands for specific issues.
# set -o nounset

# TEMPLATE: Capture starting timestamp and display no matter how it ends:
EPOCH_START="$(date -u +%s)"  # such as 1572634619
LOG_DATETIME=$(date +%Y-%m-%dT%H:%M:%S%z)-$((1 + RANDOM % 1000))

#FREE_DISKBLOCKS_START="$(df -k . | cut -d' ' -f 6)"  # 910631000 Available

trap this_ending EXIT
trap this_ending INT QUIT TERM
this_ending() {
   EPOCH_END=$(date -u +%s);
   DIFF=$((EPOCH_END-EPOCH_START))
#   FREE_DISKBLOCKS_END="$(df -k . | cut -d' ' -f 6)"
#   DIFF=$(((FREE_DISKBLOCKS_START-FREE_DISKBLOCKS_END)))
#   MSG="End of script after $((DIFF/360)) minutes and $DIFF bytes disk space consumed."
   #   info 'Elapsed HH:MM:SS: ' $( awk -v t=$beg-seconds 'BEGIN{t=int(t*1000); printf "%d:%02d:%02d\n", t/3600000, t/60000%60, t/1000%60}' )
#   success "$MSG"
   #note "$FREE_DISKBLOCKS_START to 
   #note "$FREE_DISKBLOCKS_END"
}
sig_cleanup() {
    trap '' EXIT  # some shells call EXIT after the INT handler.
    false # sets $?
    this_ending
}

### Set color variables (based on aws_code_deploy.sh): 
bold="\e[1m"
dim="\e[2m"
underline="\e[4m"
blink="\e[5m"
reset="\e[0m"
red="\e[31m"
green="\e[32m"
blue="\e[34m"
cyan="\e[36m"

h2() {     # heading
  printf "\n${bold}>>> %s${reset}\n" "$(echo "$@" | sed '/./,$!d')"
}
info() {   # output on every run
  printf "${dim}\n➜ %s${reset}\n" "$(echo "$@" | sed '/./,$!d')"
}
RUN_VERBOSE=true
note() { if [ "${RUN_VERBOSE}" = true ]; then
   printf "${bold}${cyan} ${reset} ${cyan}%s${reset}\n" "$(echo "$@" | sed '/./,$!d')"
   fi
}
success() {
  printf "${green}✔ %s${reset}\n" "$(echo "$@" | sed '/./,$!d')"
}
error() {
  printf "${red}${bold}✖ %s${reset}\n" "$(echo "$@" | sed '/./,$!d')"
}
warnNotice() {
  printf "${cyan}✖ %s${reset}\n" "$(echo "$@" | sed '/./,$!d')"
}
warnError() {
  printf "${red}✖ %s${reset}\n" "$(echo "$@" | sed '/./,$!d')"
}


###############

DOCKER_DB_NANE="snoodle-postgres"
DOCKER_APP_NANE="snoodle"

h2 "Processes now ..."
   note "$( ps -al )"

   RESULT="$( docker inspect -f '{{.State.Running}}' $DOCKER_DB_NANE )"
   if [ "$RESULT" = true ]; then  # Docker is running!
      docker container ls
         # CONTAINER ID        IMAGE               COMMAND                  CREATED              STATUS              PORTS                    NAMES
         # 8d0ce40c63bf        postgres            "docker-entrypoint.s…"   About a minute ago   Up About a minute   0.0.0.0:5432->5432/tcp   snoodle-postgres
   fi


h2 "Inside snoodle-api ..."

# docker exec -it 

# cd snoodle-api
	note "$( pwd )"


h2 "Run Flask ..."
FLASK_APP=snoodle DB_HOST=localhost \
   DB_USERNAME=snoodle \
   DB_PASSWORD=USE_IAM \
   DB_NAME=snoodle HTTP_SCHEME=https \
   python3 -m flask run 

      # Error: Could not import "snoodle".

# With postgres app
#FLASK_APP=snoodle python3 -m flask run

# shell into db
psql postgresql://snoodle:snoodle@localhost:5432/snoodle
   # psql (9.2.24, server 12.1 (Debian 12.1-1.pgdg100+1))
   # WARNING: psql version 9.2, server version 12.0.
   #          Some psql features might not work.
   # Type "help" for help.
   # 
   # snoodle=# 
   # \q 


# cd snoodle-ui  ???


npm install
npm start

