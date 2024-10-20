#!/bin/bash
echo
echo " [ $(basename $BASH_SOURCE) ] "
LOCKFILE="/tmp/$(basename $BASH_SOURCE).rotlock"
if ls /tmp/*.rotlock 1> /dev/null 2>&1; then
echo "Other job is still running. Exiting."
exit 1
fi
touch "$LOCKFILE"
trap "rm -f $LOCKFILE" EXIT

echo
echo -n "Starting in 3.."
sleep 1
echo -n " 2.."
sleep 1
echo " 1.."
sleep 1
echo
###############################################
################ S T A R T ####################
###############################################

echo -e "\n [ Put /home/l/Makefile ]\n"
tee /home/l/Makefile <<'EOF'
.DEFAULT_GOAL := ms

ms:
	sudo docker compose up -d; sudo docker attach ms
.PHONY:ms

wake:
	sudo etherwake $(	awk '/192.168.13.14/ {print $4}' /proc/net/arp )
.PHONY:wake

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

clean: blinkred
	sudo docker compose -f /opt/berry/docker-compose.yaml down -v ; \
	sudo umount /media/rr ; \
	sudo cryptsetup close rr ; \
	sudo umount /media/rr ; \
	sudo cryptsetup close rr ; \
	sudo umount /media/ww ; \
	sudo cryptsetup close ww ; \
	sudo umount /mnt/team ;
.PHONY:clean

shutdown:
	sudo sync; sudo sync; sudo sync; sudo shutdown -h now
.PHONY:shutdown

tmux: blinkred
	tmux new -A -s 0
.PHONY: tmux

mon: blinkred
	if tmux has-session -t 0 > /dev/null 2>&1; then tmux a -t 0; else \
					tmux -2 new-session -d -x "270" -y "90" -s "0" 'lsblk; fortune -s;vnstat -i wlan0; bash'   ; \
									tmux split-window -t "0:0"             -h -l 40%    -d 'journalctl -f --dmesg --output=short --no-host --no-pager | ccze'   ; \
									tmux split-window -t "0:0"             -v -l 6% -b -d 'watch -t -n4 vcgencmd measure_temp'   ; \
									tmux split-window -t "0:0"             -v -l 6% -b -d 'vnstat -i wlan0 -l '   ; \
									tmux select-window -t "0:0"   ; \
									tmux -2 attach-session -t "0"   ; \
	fi
.PHONY: mon

mon2: blinkred
	tmux split-window -t "0:0"             -h -l 40%    -d 'journalctl -f --dmesg --output=short --no-host --no-pager | ccze'   ; \
	tmux split-window -t "0:0"             -v -l 6% -b -d 'watch -t -n4 vcgencmd measure_temp'   ; \
	tmux split-window -t "0:0"             -v -l 6% -b -d 'vnstat -i wlan0 -l '   ; \
	tmux select-window -t "0:0"   ; \
	tmux -2 attach-session -t "0"   ;
.PHONY: mon2

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
	sudo docker compose -f /opt/berry/docker-compose.yaml up -d
.PHONY: docker

undocker: blinkred
	sudo docker compose -f /opt/berry/docker-compose.yaml down -v
EOF
ls -lah Makefile 

###############################################
################## E N D ######################
###############################################
echo
echo -n "Ending in 3.."
sleep 1
echo -n " 2.."
sleep 1
echo " 1.."
sleep 1
echo
