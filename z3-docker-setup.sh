#!/bin/bash
set -euo pipefail
echo;echo " [ $(basename $BASH_SOURCE) ] "
LOCKFILE="/tmp/$(basename $BASH_SOURCE).rotlock"
if ls /tmp/*.rotlock 1> /dev/null 2>&1; then
echo "Other job is still running. Exiting."
exit 1
fi
touch "$LOCKFILE"; trap "rm -f $LOCKFILE" EXIT
echo;echo -n "Starting in 3..";sleep 1;echo -n " 2..";sleep 1;echo " 1..";sleep 1;echo
###############################################
################ S T A R T ####################
###############################################

echo -e "\n [ Install python & pip ]\n"
sudo apt-get install -y python3-pip


# taken from : https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository
echo -e "\n [ Add Docker official GPG key ]\n"
sudo apt-get update
sudo apt-get install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo -e "\n [ Add Docker repository to Apt sources ]\n"
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

echo -e "\n [ Install the latest version of Docker ]\n"
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo systemctl enable docker

###############################################
################## E N D ######################
###############################################
echo;echo -n "Ending in 3..";sleep 1;echo -n " 2..";sleep 1;echo " 1..";sleep 1;echo
