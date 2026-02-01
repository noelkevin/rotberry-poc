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

echo -e "\n [ Put /home/l/Makefile ]\n"
tee /home/l/Makefile <<'EOF'
.DEFAULT_GOAL := ms

ms:
	sudo docker compose up -d; sudo docker attach ms
.PHONY:ms

blinkred:
	@sudo sh -c "echo 1 > /sys/class/leds/PWR/brightness";sleep 0.1;sudo sh -c "echo 0 > /sys/class/leds/PWR/brightness";sudo sh -c "echo 1 > /sys/class/leds/PWR/brightness";sleep 0.1;sudo sh -c "echo 0 > /sys/class/leds/PWR/brightness";sudo sh -c "echo 1 > /sys/class/leds/PWR/brightness";sleep 0.1;sudo sh -c "echo 0 > /sys/class/leds/PWR/brightness";
.PHONY: blinkred

wifi: blinkred
	sudo vim /etc/netplan/50-cloud-init.yaml
	sudo netplan apply
.PHONY:wifi

restart:
	sudo sync; sudo sync; sudo sync; sudo reboot -h now
.PHONY:restart

reboot:
	sudo sync; sudo sync; sudo sync; sudo reboot -h now
.PHONY:reboot

shutdown:
	sudo sync; sudo sync; sudo sync; sudo shutdown -h now
.PHONY:shutdown

tmux: blinkred
	tmux new -A -s 0
.PHONY: tmux

ap: blinkred
	sudo systemctl enable create_ap && sudo service create_ap restart
.PHONY: ap

aprm: blinkred
	sudo service create_ap stop
.PHONY: aprm

shark: blinkred
	sudo termshark -i wlan0 -Y='mdns or dns'
.PHONY: shark

browser:
	sudo docker run --rm -ti --network host fathyb/carbonyl:latest-arm64 https://www.google.com/gen_204
.PHONY: browser

ww: blinkred
	sudo cryptsetup open --type luks /mnt/team/w.w.syncthing ww
	sudo mount /dev/mapper/ww /media/ww
.PHONY: ww
unww: blinkred
	sudo umount /media/ww
	sudo cryptsetup close ww
.PHONY: unww

rr: blinkred
	sudo cryptsetup open --type luks /mnt/team/r.r.syncthing rr
	sudo mount /dev/mapper/rr /media/rr
.PHONY: rr
unrr: blinkred
	sudo umount /media/rr
	sudo cryptsetup close rr
.PHONY: unrr

docker: blinkred
	sudo docker compose up -d
.PHONY: docker

undocker: blinkred
	sudo docker compose down -v
.PHONY: undocker

_initoverlayroot: blinkred
	sudo apt-get -y remove unattended-upgrades
	sudo apt-get install overlayroot
	sudo sed -i.bak 's|^overlayroot=.*|overlayroot="tmpfs:swap=1,recurse=0"|' /etc/overlayroot.conf
	sudo systemctl stop log2ram
	sudo systemctl disable log2ram
	sudo sed -i.bak '/^tmpfs \/tmp/ s/^/#/' /etc/fstab
.PHONY: _initoverlayroot

overlayroot: blinkred
	sudo sed -i.bak 's|^overlayroot=.*|overlayroot="tmpfs:swap=1,recurse=0"|' /etc/overlayroot.conf
	echo "reboot to apply"
.PHONY: overlayroot

overlayrootrm: blinkred
	sudo overlayroot-chroot sudo sed -i.bak 's|^overlayroot=.*|overlayroot=""|' /etc/overlayroot.conf
	echo "reboot to apply removal"
.PHONY: overlayrootrm

_initdockeroverlay: blinkred
	sudo apt-get -y install fuse-overlayfs
	sudo docker ps -aq | xargs -r sudo docker stop
	sudo docker ps -aq | xargs -r sudo docker rm
	sudo docker images -q | xargs -r sudo docker rmi
	sudo docker builder prune -f
	echo '{ "storage-driver": "fuse-overlayfs" }' | sudo tee /etc/docker/daemon.json
	sudo systemctl restart docker
	sudo docker info | grep -E "Storage Driver|Docker Root Dir"
.PHONY: _initdockeroverlay

wonder: blinkred
	sudo ethtool -K wlan0 tso off
	sudo ethtool -K xwlan tso off
	sudo wondershaper -a wlan0 -c; sudo wondershaper -a wlan0 -u 60000 -d 60000;
	sudo wondershaper -a xwlan -c; sudo wondershaper -a xwlan -u 60000 -d 180000;
.PHONY: wonder

wonderrm: blinkred
	sudo wondershaper -c -a wlan0
	sudo wondershaper -c -a eth0
	sudo wondershaper -c -a tailscale0
	sudo wondershaper -c -a xwlan
.PHONY: wonderrm

EOF
ls -lah Makefile

###############################################
################## E N D ######################
###############################################
echo;echo -n "Ending in 3..";sleep 1;echo -n " 2..";sleep 1;echo " 1..";sleep 1;echo
