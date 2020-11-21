#!/bin/bash

# poza serwerem produkcyjym nie zadziala

set -e 
 
working_dir=$1
lock_file_or_dir="./.update.lock"
cmd_locking="touch ${lock_file_or_dir}"
cmd_check_lock="test -f ${lock_file_or_dir}"
cmd_unlocking="rm -rf ${lock_file_or_dir}"

function is_already_running()
{
  local cmd_check_lock=${1}
  ${cmd_check_lock} |{
    return 1
   }
}

function create_lock()
{   
  local cmd_locking=${1}

  ${cmd_locking} || {
     printf "cannot create lock \n"
     exit 2
   }
}

function remove_lock()
{
  local cmd_unlocking="${1}"
  ${cmd_unlocking} || {
    printf "Cannot unlock\n"
    exit 3
  }
}

trap 'remove_lock "${cmd_unlocking}"' SIGINT SIGTERM

if is_already_running "${cmd_check_lock}"; then
  printf "Cannot acquire lock - another instance is running, exiting \n"
  exit 1
fi

create_lock "${cmd_locking}"
##############################################################
# sudo yum install git 
# sudo yum install -y yum-utils
# sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
# sudo yum install -y docker-ce docker-ce-cli containerd.io

echo "################################################"
echo "Uruchomienie docker swarm"
docker swarm init | true

echo "################################################"
echo "Aktualizacja submodulow do maina"
git submodule foreach git pull origin main

echo "################################################"
echo "Tworzenie sieci z sterownikiem overlay"
docker network create -d overlay over | true

echo "################################################"
echo "Uruchamianie aplikacji glownej" 
cd aplikacja-glowna
docker stack deploy -c docker-compose.yaml app_glowna

echo "#################################################"
echo "Uruchamianie plikacji testujacej"
cd ../aplikacja-testujaca
docker stack deploy -c docker-compose.yaml app_test

###############################################################
remove_lock "${cmd_unlocking}"