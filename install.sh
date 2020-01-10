#!/usr/bin/env bash

# install.sh in https://github.com/wilsonmar/dev-bootcamp
# This downloads and installs all the utilities, then verifies.
# After getting into the Cloud9 enviornment,
# cd to folder, copy this line and paste in the Cloud9 terminal:
# bash -c "$(curl -fsSL https://git.btcmp-team2.mckinsey.cloud/snippets/1/raw)"
# bash -c "$(curl -fsSL https://raw.githubusercontent.com/wilsonmar/dev-bootcamp/master/bash/install.sh)"

# This was tested on macOS Mojava and Amazon Linux 2018.2 in EC2.


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

# Check what operating system is used now.
   OS_TYPE="$(uname)"
   OS_DETAILS=""  # default blank.
if [ "$(uname)" == "Darwin" ]; then  # it's on a Mac:
      OS_TYPE="macOS"
      PACKAGE_MANAGER="brew"
elif [ "$(uname)" == "Linux" ]; then  # it's on a Mac:
   if command -v lsb_release ; then
      lsb_release -a
      OS_TYPE="Ubuntu"  # for apt-get
      PACKAGE_MANAGER="apt-get"
   elif [ -f "/etc/os-release" ]; then
      OS_DETAILS=$( cat "/etc/os-release" )  # ID_LIKE="rhel fedora"
      OS_TYPE="Fedora"  # for yum 
      PACKAGE_MANAGER="yum"
   elif [ -f "/etc/centos-release" ]; then
      OS_TYPE="CentOS"  # for yum
      PACKAGE_MANAGER="yum"
   else
      error "Linux distribution not anticipated. Please update script. Aborting."
      exit 0
   fi
else 
   error "Operating system not anticipated. Please update script. Aborting."
   exit 0
fi
HOSTNAME=$( hostname )
PUBLIC_IP=$( curl -s ifconfig.me )


# h2 "STEP 1 - Ensure run variables are based on arguments or defaults ..."
args_prompt() {
   echo "This bash shell script installs for dev-codecamp within an AWS EC2."
   echo "USAGE EXAMPLE during testing (minimal inputs using defaults):"
   #echo "   ./install.sh -u \"John Doe\" -e \"john_doemckinsey.com\" -v -D"
   echo "OPTIONS:"
   echo "   -n       GitHub user name"
   echo "   -e       GitHub user email"
   echo "   -R       reboot Docker before run"
   echo "   -v       to run verbose (list space use and each image to console)"
   echo "   -d       to delete files after run (to save disk space)"
 }
if [ $# -eq 0 ]; then  # display if no paramters are provided:
   args_prompt
fi
exit_abnormal() {                              # Function: Exit with error.
  args_prompt
  exit 1
}
# Defaults:
UPDATE_PKGS=true
RESTART_DOCKER=false
SECRETS_FILEPATH="$HOME/secrets.sh"  # -s
GITHUB_USER_NAME=""                  # -n
GITHUB_USER_EMAIL=""                 # -e

RUN_ACTUAL=true  # false as dry run is default.  TODO: Add parse of command parameters
RUN_DELETE_AFTER=false     # -D
while test $# -gt 0; do
  case "$1" in
    -h|--help)
      args_prompt
      exit 0
      ;;
    -n*)
      shift
      export GITHUB_USER_NAME=`echo $1 | sed -e 's/^[^=]*=//g'`
      shift
      ;;
    -e*)
      shift
      export GITHUB_USER_EMAIL=`echo $1 | sed -e 's/^[^=]*=//g'`
      shift
      ;;
    -s*)
      shift
      export SECRETS_FILEPATH=`echo $1 | sed -e 's/^[^=]*=//g'`
      shift
      ;;
    -U)
      export UPDATE_PKGS=true
      shift
      ;;
    -R)
      export RESTART_DOCKER=true
      shift
      ;;
    -v)
      export RUN_VERBOSE=true
      shift
      ;;
    -D)
      export RUN_DELETE_AFTER=true
      shift
      ;;
    *)
      error "Parameter \"$1\" not recognized. Aborting."
      exit 0
      break
      ;;
  esac
done


#################### Print run heading:

      note "From $0 in $PWD"
      note "Bash $BASH_VERSION at $LOG_DATETIME"  # built-in variable.
      note "OS_TYPE=$OS_TYPE on hostname=$HOSTNAME at PUBLIC_IP=$PUBLIC_IP."
   if [ -f "$OS_DETAILS" ]; then
      note "$OS_DETAILS"
   fi


### Get secrets from $HOME/secrets.sh

h2 "Config git/GitHub user.name & email"
   if [ -f "$SECRETS_FILEPATH" ]; then
      chmod +x "$SECRETS_FILEPATH"
      source   "$SECRETS_FILEPATH"  # run file containing variable definitions.
      note "GITHUB_USER_NAME=\"$GITHUB_USER_NAME\" read from file $SECRETS_FILEPATH"
   else
      read -p "Enter your GitHub user name [John Doe]: " GITHUB_USER_NAME
      GITHUB_USER_NAME=${GITHUB_USER_NAME:-"John Doe"}
      read -p "Enter your GitHub user email [john_doe@mckinsey.com]: " GITHUB_USER_EMAIL
      GITHUB_USER_EMAIL=${GITHUB_USER_EMAIL:-"John_Doe@mckinsey.com"}
      # cp secrets.sh  "$SECRETS_FILEPATH"
   fi
   git config --global user.name  "$GITHUB_USER_NAME"
   git config --global user.email "$GITHUB_USER_EMAIL"


## Setup env

h2 "Install package managerss:"
   if [ PACKAGE_MANAGER == "yum" ]; then
      if [ "${UPDATE_PKGS}" = true ]; then
         sudo yum install ...
      fi
   elif [ PACKAGE_MANAGER == "brew" ]; then
      if ! command -v brew ; then
         info "Installing brew ..."
         ## Install Ruby ...
      else
         if [ "${UPDATE_PKGS}" = true ]; then
            info "Upgrading brew ..."
         fi
      fi
   fi


h2 "Install Postgres packages:"
   if [ PACKAGE_MANAGER == "yum" ]; then
      sudo yum -y install postgresql postgresql-server postgresql-devel postgresql-contrib postgresql-docs
      if [ "${RUN_VERBOSE}" = true ]; then
         sudo yum list installed
      fi
   elif [ PACKAGE_MANAGER == "brew" ]; then
      brew install postgresql postgresql-server postgresql-devel postgresql-contrib postgresql-docs
      if [ "${RUN_VERBOSE}" = true ]; then
         brew list
      fi
   fi
   note "$( postgres --version )"  # postgres (PostgreSQL) 9.2.24


h2 "Install Python ecosystem:"
   note "$PWD"
   curl -O https://bootstrap.pypa.io/get-pip.py
      #  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
      #                                   Dload  Upload   Total   Spent    Left  Speed
      # 100 1734k  100 1734k    0     0  35.2M      0 --:--:-- --:--:-- --:--:-- 36.0M   
   python3 get-pip.py --user
      # Collecting pip
      # Using cached https://files.pythonhosted.org/packages/00/b6/9cfa56b4081ad13874b0c6f96af8ce16cfbc1cb06bedf8e9164ce5551ec1/pip-19.3.1-py2.py3-none-any.whl
      # Successfully installed pip-19.3.1
   pip3 install pipenv --user


h2 "Install aliases, PS1, etc. in ~/.bashrc ..."
   curl -o ~/.git-prompt.sh \
      https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh
         # 100 16938  100 16938    0     0   124k      0 --:--:-- --:--:-- --:--:--  124k

   # Add to your ~/.bash_profile:
   source ~/.git-prompt.sh

   . ~/.bash_profile
   # Prompt should now be: (master)Developer:~/environment/snoodle-ui (master) $


# h2 "Install Docker ..."


# "/snoodle-postgres" is already in use

   if [ "$RESTART_DOCKER" = false ]; then
      note "Not restarting Docker ..."
   else
      h2 "1.2 Restarting Docker ..." 
      # Restart Docker to avoid:
      # Cannot connect to the Docker daemon at unix:///var/run/docker.sock. 
      # Is the docker daemon running?.
      killall com.docker.osx.hyperkit.linux
   fi


h2 "Run Docker ..."
   docker run --rm --name snoodle-postgres -p 5432:5432 \
   -e POSTGRES_USER=snoodle \
   -e POSTGRES_PASSSWORD=snoodle \
   -e POSTGRES_DB=snoodle \
   postgres &
      # 2020-01-10 01:22:30.904 UTC [1] LOG:  listening on IPv4 address "0.0.0.0", port 5432
      # 2020-01-10 01:22:30.904 UTC [1] LOG:  listening on IPv6 address "::", port 5432
      # 2020-01-10 01:22:30.909 UTC [1] LOG:  listening on Unix socket "/var/run/postgresql/.s.PGSQL.5432"
      # database system is ready to accept connections

   note "$( ps -al )"

# openvt
# deallocvt n

exit  # TODO:


h2 "Inside Docker: Run Flask ..."

# docker exec -it 

cd snoodle-api
FLASK_APP=snoodle DB_HOST=localhost \
   DB_USERNAME=snoodle \
   DB_PASSWORD=USE_IAM \
   DB_NAME=snoodle HTTP_SCHEME=https \
   python3 -m flask run 

# With postgres app
FLASK_APP=snoodle python3 -m flask run

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

