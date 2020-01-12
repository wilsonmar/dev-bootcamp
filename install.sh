#!/usr/bin/env bash

# install.sh in https://github.com/wilsonmar/dev-bootcamp
# This downloads and installs all the utilities, then verifies.
# After getting into the Cloud9 enviornment,
# cd to folder, copy this line and paste in the Cloud9 terminal:
# bash -c "$(curl -fsSL https://raw.githubusercontent.com/wilsonmar/dev-bootcamp/master/install.sh)" -v

# This was tested on macOS Mojave and Amazon Linux 2018.2 in EC2.


### STEP 1. Set display utilities:

clear  # screen (but not history)

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
   elif [ -f "/etc/redhat-release" ]; then
      OS_DETAILS=$( cat "/etc/redhat-release" )  # ID_LIKE="rhel fedora"
      OS_TYPE="RedHat"  # for yum 
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

# Defaults (default true so flag turns it true):
   UPDATE_PKGS=false
   RESTART_DOCKER=false
   RUN_ACTUAL=false  # false as dry run is default.
   RUN_DELETE_AFTER=false     # -D

DOCKER_DB_NANE="snoodle-postgres"
DOCKER_APP_NANE="snoodle"

SECRETS_FILEPATH="$HOME/secrets.sh"  # -s
GITHUB_USER_NAME=""                  # -n
GITHUB_USER_EMAIL=""                 # -e


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

cd ~/environment/

      note "From $0 in $PWD"
      note "Bash $BASH_VERSION at $LOG_DATETIME"  # built-in variable.
      note "OS_TYPE=$OS_TYPE on hostname=$HOSTNAME at PUBLIC_IP=$PUBLIC_IP."
   if [ -f "$OS_DETAILS" ]; then
      note "$OS_DETAILS"
   fi


h2 "Downloading bash script install.sh ..."
   curl -s -O https://raw.githubusercontent.com/wilsonmar/dev-bootcamp/master/install.sh


h2 "Install aliases, PS1, etc. in ~/.bashrc ..."
   curl -s -o ~/.git-prompt.sh \
      https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh
         # 100 16938  100 16938    0     0   124k      0 --:--:-- --:--:-- --:--:--  124k

   # Add to your ~/.bash_profile:
   source ~/.git-prompt.sh

   . ~/.bash_profile
   # Prompt should now be: (master)Developer:~/environment/snoodle-ui (master) $



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

   if [ PACKAGE_MANAGER == "brew" ]; then
      if ! command -v brew ; then
         h2 "Installing brew package manager using Ruby ..."
         mkdir homebrew && curl -L https://github.com/Homebrew/brew/tarball/master \
            | tar xz --strip 1 -C homebrew
      else
         if [ "${UPDATE_PKGS}" = true ]; then
            h2 "Upgrading brew ..."
         fi
      fi
      note "$( brew --version)"
         # Homebrew 2.2.2
         # Homebrew/homebrew-core (git revision e103; last commit 2020-01-07)
         # Homebrew/homebrew-cask (git revision bbf0e; last commit 2020-01-07)
   elif [ PACKAGE_MANAGER == "apt-get" ]; then
       apt-get install python-pip

   elif [ PACKAGE_MANAGER == "yum" ]; then
      if ! command -v yum ; then
         h2 "Installing yum package manager ..."
      else
         if [ "${UPDATE_PKGS}" = true ]; then
            yum -y install python-pip
         fi
      fi
   fi



h2 "Install Python pip ecosystem:"
   curl -s -O https://bootstrap.pypa.io/get-pip.py
      #  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
      #                                   Dload  Upload   Total   Spent    Left  Speed
      # 100 1734k  100 1734k    0     0  35.2M      0 --:--:-- --:--:-- --:--:-- 36.0M   
   python3 get-pip.py --user
      # Collecting pip
      # Using cached https://files.pythonhosted.org/packages/00/b6/9cfa56b4081ad13874b0c6f96af8ce16cfbc1cb06bedf8e9164ce5551ec1/pip-19.3.1-py2.py3-none-any.whl
      # Successfully installed pip-19.3.1
   note "$( pip --version )" 
      # ON MACOS: pip 19.3.1 from /Users/wilson_mar/Library/Python/3.7/lib/python/site-packages/pip (python 3.7)
      # ON CENTO: pip 9.0.3 from /usr/lib/python2.7/dist-packages (python 2.7)

   pip3 install pipenv --user
      # for (python 3.7)
      # See https://pipenv.kennethreitz.org/en/latest/basics/

   note "$( pipenv --version )"   # pipenv, version 2018.11.26

   # .venvScriptspython.exe -m pip install flask-sqlalchemy

   # Install packages into the pipenv virtual environment and update its Pipfile:
   pipenv install Flask-SQLAlchemy
      # Installing Flask-SQLAlchemy…
      # Adding Flask-SQLAlchemy to Pipfile's [packages]…
      # ✔ Installation Succeeded 
      # Pipfile.lock (e25846) out of date, updating to (ca72e7)…
      # Locking [dev-packages] dependencies…
      # Locking [packages] dependencies…
      # ✔ Success! 
      # Updated Pipfile.lock (e25846)!
      # Installing dependencies from Pipfile.lock (e25846)…
      #      ▉▉▉▉▉▉▉▉▉▉▉▉▉▉▉▉▉▉▉▉▉▉▉▉▉▉▉▉▉▉▉▉ 8/8 — 00:00:02

   pipenv install sqlalchemy


# First remove boot2docker and Kitematic https://github.com/boot2docker/boot2docker/issues/437
if ! command -v docker >/dev/null; then  # /usr/local/bin/docker
      h2 "Installing docker ..."
      brew install docker  docker-compose  
      brew docker-machine  xhyve  docker-machine-driver-xhyve
      # This creates folder ~/.docker
      # Docker images are stored in $HOME/Library/Containers/com.docker.docker
      brew link --overwrite docker
      # /usr/local/bin/docker -> /Applications/Docker.app/Contents/Resources/bin/docker
      brew link --overwrite docker-compose

  #    brew link --overwrite docker-machine
      # docker-machine-driver-xhyve driver requires superuser privileges to access the hypervisor. To enable, execute:
      # https://www.nebulaworks.com/blog/2017/04/23/getting-started-linuxkit-mac-os-x-xhyve/
  #    sudo chown root:wheel /usr/local/opt/docker-machine-driver-xhyve/bin/docker-machine-driver-xhyve
  #    sudo chmod u+s /usr/local/opt/docker-machine-driver-xhyve/bin/docker-machine-driver-xhyve

else # Docker installed:
   if [ "${UPDATE_PKGS}" = true ]; then
         h2 "Upgrading Docker ..."
         docker version
         brew upgrade docker 
         brew upgrade docker-compose  

   #      brew upgrade docker-machine 
   #      brew upgrade docker-machine-driver-xhyve
   #      brew upgrade xhyve
   fi
   note "$( docker --version )"
fi
docker info --format "{{.OperatingSystem}}"
   # ON MACOS: Docker Desktop
   # Amazon Linux AMI 2018.03



h2 "Install Postgres packages:"
   if [ PACKAGE_MANAGER == "brew" ]; then
      brew install postgresql postgresql-server postgresql-devel postgresql-contrib postgresql-docs
      if [ "${RUN_VERBOSE}" = true ]; then
         brew list
      fi
   elif [ PACKAGE_MANAGER == "yum" ]; then
      sudo yum -y install postgresql postgresql-server postgresql-devel postgresql-contrib postgresql-docs
      if [ "${RUN_VERBOSE}" = true ]; then
         sudo yum list installed
      fi
   fi
   note "$( postgres --version )"  # postgres (PostgreSQL) 9.2.24




if [ "$RESTART_DOCKER" = false ]; then
   note "Not restarting Docker daemon ..."
else
   RESULT="$( docker inspect -f '{{.State.Running}}' $DOCKER_DB_NANE )"
   if [ ! "$RESULT" = true ]; then  # Docker is NOT running!
      h2 "1.2 Enabling and Starting Docker daemon ..." 
         # Restart Docker to avoid:
         # Cannot connect to the Docker daemon at unix:///var/run/docker.sock. 
         # Is the docker daemon running?.
         systemctl enable docker
         systemctl start docker
   else
      h2 "1.2 Restarting Docker daemon in $OS_TYPE ..." 
      if [ "$OS_TYPE" == "macOS" ]; then
         killall com.docker.osx.hyperkit.linux
      else
         # systemctl is a part of, is a service manager designed specifically for Linux 
         systemctl restart docker
      fi
   fi
fi


h2 "Remove all containers running in Docker from previous run ..."
   docker container ls -q
   #docker container ls -a --filter status=exited --filter status=created

   # Remove all running containers:  
   docker rm `docker container ls -q` --force
   # To remove stopped containers as well before shutting down environment:
   #docker container prune --force


   h2 "Stop any active containers (Postgres) ..."
   # See https://linuxize.com/post/how-to-remove-docker-images-containers-volumes-and-networks/
   ACTIVE_CONTAINERS=$( docker container ls -aq )
   if [ ! -z "$ACTIVE_CONTAINERS" ]; then  # var blank
      note "Stopping active container $ACTIVE_CONTAINERS ..."
      docker container stop "$ACTIVE_CONTAINERS"
      if [ "$RUN_VERBOSE" = true ]; then
         docker ps  # should not list docker now.
      fi
   fi



h2 "Run Docker detached container \"$DOCKER_DB_NANE\" ..."
   nohup docker run -d --rm --name "$DOCKER_DB_NANE" -p 5432:5432 \
   -e POSTGRES_USER=snoodle \
   -e POSTGRES_PASSSWORD=snoodle \
   -e POSTGRES_DB=snoodle postgres
      # 2020-01-10 01:22:30.904 UTC [1] LOG:  listening on IPv4 address "0.0.0.0", port 5432
      # 2020-01-10 01:22:30.904 UTC [1] LOG:  listening on IPv6 address "::", port 5432
      # 2020-01-10 01:22:30.909 UTC [1] LOG:  listening on Unix socket "/var/run/postgresql/.s.PGSQL.5432"
      # database system is ready to accept connections

# control+C to exit here.

   docker container ls

h2 "Run Python Flask snoodle-api app ..."
cd snoodle-api
ls
#if [ ! -f "snoodle/app.py" ]; then
#   error "Flask app not found. Aborting."
#else
   FLASK_APP=snoodle DB_HOST=localhost \
      DB_USERNAME=snoodle \
      DB_PASSWORD=USE_IAM \
      DB_NAME=snoodle HTTP_SCHEME=https 
   python3 -m flask run 
#fi

# openvt
# deallocvt n


