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

echo -e "\n [ Update ]\n"
sudo apt-get -y update && sudo apt-get -y upgrade \
&& sudo apt-get -y autoclean && sudo apt-get -y autoremove
echo -e "\n [ Remove old firmware ]\n"
sudo rm -rf /boot/firmware/*.bak
du -sh  /boot/firmware/

echo -e "\n [ Replace values in /etc/ssh/sshd_config ]\n"
sudo sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
grep PasswordAuthentication /etc/ssh/sshd_config

echo -e "\n [ Install prerequisites for packages ]\n"
sudo apt-get -y install unzip git curl

echo -e "\n [ Skip prompt via debconf when installing packages ]\n"
echo PURGE | sudo debconf-communicate iperf3
echo "iperf3 iperf3/start_daemon boolean false" | sudo debconf-set-selections
# How to get debconf: sudo debconf-show

echo -e "\n [ Install packages ]\n"
sudo apt-get -y install linux-modules-extra-$(uname -r) \
&& sudo apt-get -y install build-essential apt-offline \
&& sudo apt-get -y install iw wpasupplicant net-tools hostapd dnsmasq haveged \
&& sudo apt-get -y install wireless-tools nethogs pv rfkill \
&& sudo apt-get -y install libfuse2 pcscd \
&& sudo apt-get -y install exfatprogs \
&& sudo apt-get -y install jq yq \
&& sudo apt-get -y install vnstat smartmontools\
&& sudo apt-get -y install iperf3 speedtest-cli btop \
&& sudo apt-get -y install hashdeep \
&& sudo apt-get -y install ccze fortune \
&& sudo apt-get autoremove

echo -e "\n [ Override python managed installation ]\n"
sudo rm -f /usr/lib/python3.*/EXTERNALLY-MANAGED

echo -e "\n [ Install Log2ram ]\n"

sudo systemctl list-unit-files log2ram.service &>/dev/null && sudo systemctl stop log2ram
mkdir -p /tmp/log2ram
curl -L https://github.com/azlux/log2ram/archive/master.tar.gz | tar zxf - -C /tmp/log2ram
cd /tmp/log2ram/log2ram-master && chmod +x install.sh && sudo ./install.sh && cd /home/l

echo -e "\n [ Create mount folders ]\n"
sudo mkdir -p /mnt/jeyi
sudo mkdir -p /mnt/hagibis
sudo mkdir -p /mnt/team
sudo mkdir -p /mnt/cs
sudo mkdir -p /mnt/green
sudo mkdir -p /mnt/wdsn
ls -lah /media

echo -e "\n [ Add disks to /etc/fstab ]\n"
sudo cp /etc/fstab /etc/fstab.bak
sudo cp /etc/fstab /etc/fstab.tmp
grep -q '/mnt/jeyi' /etc/fstab.tmp || echo 'UUID=7e97726a-d606-49d9-9cfc-05e838b246bf /mnt/jeyi ext4 auto,rw,nofail,defaults,discard,noatime  0 0' | sudo tee -a /etc/fstab.tmp
grep -q '/mnt/team' /etc/fstab.tmp || echo 'UUID=e90d74eb-d5e2-457e-acdf-5f4fb4e51797 /mnt/team ext4 auto,rw,nofail,defaults,discard,noatime 0 0' | sudo tee -a /etc/fstab.tmp
grep -q '/mnt/cs' /etc/fstab.tmp || echo 'UUID=9ec8096a-fbf5-4e38-9a44-80bad3173ab7 /mnt/cs auto nosuid,nodev,nofail,noatime,x-gvfs-show,discard,x-gvfs-name=cs 0 0' | sudo tee -a /etc/fstab.tmp
grep -q '/mnt/wdsn' /etc/fstab.tmp || echo 'UUID=cafe67cc-ad56-470b-b5d8-51e509906f93 /mnt/wdsn ext4 auto,rw,nofail,defaults,noatime 0 0' | sudo tee -a /etc/fstab.tmp
grep -q '/mnt/hagibis' /etc/fstab.tmp || echo 'UUID=6724-7EB8 /mnt/hagibis exfat auto,rw,nofail,defaults,uid=1000,gid=1003,noatime  0 0' | sudo tee -a /etc/fstab.tmp
grep -q '/mnt/green' /etc/fstab.tmp || echo 'UUID=76FD-CAD8 /mnt/green auto nosuid,nodev,nofail,noatime,x-gvfs-show,x-gvfs-name=green,uid=1000,gid=1000 0 0' | sudo tee -a /etc/fstab.tmp
grep -q '/mnt/ACASISDISK1' /etc/fstab.tmp || echo 'UUID=681E-6FC4 /mnt/ACASISDISK1 exfat auto,rw,user,nofail,defaults,uid=1000,gid=1003,noatime,exec  0 0' | sudo tee -a /etc/fstab.tmp
grep -q '/mnt/ACASISDISK2' /etc/fstab.tmp || echo 'UUID=681E-6FD9 /mnt/ACASISDISK2 exfat auto,rw,user,nofail,defaults,uid=1000,gid=1003,noatime,exec  0 0' | sudo tee -a /etc/fstab.tmp
grep -q 'btrfsbak' /etc/fstab.tmp || echo 'LABEL=btrfsbak /mnt/bak btrfs noatime,compress=zstd:3,ssd_spread,space_cache=v2,nofail  0  0' | sudo tee -a /etc/fstab.tmp
grep -q '65c85fd8-ee84-4efd-b34e-c5e870ac9559 ' /etc/fstab.tmp || echo 'UUID=65c85fd8-ee84-4efd-b34e-c5e870ac9559 /mnt/lv2 ext4 auto,rw,nofail,defaults,discard,noatime,errors=remount-ro,commit=60 0 0' | sudo tee -a /etc/fstab.tmp
grep -q '/tmp' /etc/fstab.tmp || echo 'tmpfs /tmp tmpfs mode=1777,strictatime,nosuid,nodev,size=2G,nr_inodes=1m 0 0' | sudo tee -a /etc/fstab.tmp

sudo mv -f /etc/fstab.tmp /etc/fstab
sudo findmnt --verify --verbose || true
sudo systemctl daemon-reload
sudo mount -a
df -h

echo -e "\n [ Enable ssd trim on /etc/udev/rules.d/60-trim-rtl9210.rules ]\n"
sudo tee /etc/udev/rules.d/60-trim-rtl9210.rules <<'EOF'
ACTION=="add|change", ATTRS{idVendor}=="0bda", ATTRS{idProduct}=="9210", SUBSYSTEM=="scsi_disk", ATTR{provisioning_mode}="unmap"
EOF

echo -e "\n [ Enable ssd trim on /etc/udev/rules.d/61-trim-jms583.rules ]\n"
sudo tee /etc/udev/rules.d/61-trim-jms583.rules <<'EOF'
ACTION=="add|change", ATTRS{idVendor}=="152d", ATTRS{idProduct}=="f583", SUBSYSTEM=="scsi_disk", ATTR{provisioning_mode}="unmap"
EOF

echo -e "\n [ limit /var/log ]\n"
sudo sed -r -i.orig 's/#?SystemMaxUse=/SystemMaxUse=150M/g' /etc/systemd/journald.conf
sudo systemctl restart systemd-journald
du -sh /var/log/journal/

echo -e "\n [ Setup UFW ]\n"
sudo ufw --force reset
sudo ufw default allow routed
echo ssh ;                sudo ufw allow proto tcp from any to any port 22 comment 'ssh'
echo dns;                 sudo ufw allow out to any port 53 comment 'dns'
echo nginx ;              sudo ufw allow proto tcp from any to any port 80,443 comment 'nginx'
echo iperf3 ;             sudo ufw allow from any to any port 5201 comment 'iperf3'
echo mdns;                sudo ufw allow in proto udp to 224.0.0.251 port 5353 comment 'mdns'
echo syncthing ;          sudo ufw allow proto tcp from any to any port 22000:22003,8384 comment 'syncthing'
echo syncthing ;          sudo ufw allow proto udp from any to any port 22000:22003,21027 comment 'syncthing'
echo immich;              sudo ufw allow proto tcp from 192.168.0.0/16 to 192.168.0.0/16 port 2283 comment 'immich'
echo kdeconnect;          sudo ufw allow proto tcp from 192.168.0.0/16 to 192.168.0.0/16 port 1714:1764 comment 'kdeconnect'
echo kdeconnect;          sudo ufw allow proto udp from 192.168.0.0/16 to 192.168.0.0/16 port 1714:1764 comment 'kdeconnect'
echo natpmp;              sudo ufw deny from any to any port 5351 proto udp comment 'natpmp'
echo redlib;              sudo ufw allow from 172.0.0.0/8 to 172.17.0.1 port 22222 comment 'redlib'
echo suwayomi;            sudo ufw allow from 172.0.0.0/8 to 172.17.0.1 port 22223 comment 'suwayomi'
#echo crowdsec;            sudo ufw allow proto tcp from 192.168.12.0/24 to 192.168.12.1 port 222 comment 'crowdsec'

sudo ufw --force enable;
sudo ufw status verbose;

echo -e "\n [ Adjust rpi config ]\n"
sudo sed -i 's/rootwait fixrtc/rootwait modules-load=dwc2,g_ether fixrtc/' /boot/firmware/cmdline.txt
sudo sed -i 's/^dtparam=audio=on$/dtparam=audio=off/' /boot/firmware/config.txt
grep -q hdmi_blanking=1 /boot/firmware/config.txt || echo 'hdmi_blanking=1' | sudo tee -a /boot/firmware/config.txt
grep -q dtoverlay=disable-bt /boot/firmware/config.txt || echo 'dtoverlay=disable-bt' | sudo tee -a /boot/firmware/config.txt
grep -q dtparam=eth_led0 /boot/firmware/config.txt || echo 'dtparam=eth_led0=4' | sudo tee -a /boot/firmware/config.txt
grep -q dtparam=eth_led1 /boot/firmware/config.txt || echo 'dtparam=eth_led1=4' | sudo tee -a /boot/firmware/config.txt
grep -q dtparam=pwr_led_trigger /boot/firmware/config.txt || echo 'dtparam=pwr_led_trigger=none' | sudo tee -a /boot/firmware/config.txt
grep -q dtparam=act_led_trigger=mmc0 /boot/firmware/config.txt || echo 'dtparam=act_led_trigger=mmc0' | sudo tee -a /boot/firmware/config.txt
grep -q dtparam=act_led_activelow=off /boot/firmware/config.txt || echo 'dtparam=act_led_activelow=off' | sudo tee -a /boot/firmware/config.txt
grep -q dtparam=pciex1 /boot/firmware/config.txt || echo 'dtparam=pciex1' | sudo tee -a /boot/firmware/config.txt
grep -q dtparam=pciex1_gen=3 /boot/firmware/config.txt || echo 'dtparam=pciex1_gen=3' | sudo tee -a /boot/firmware/config.txt
grep -q max_usb_current=1 /boot/firmware/config.txt || echo 'max_usb_current=1' | sudo tee -a /boot/firmware/config.txt
grep -q usb_max_current_enable=1 /boot/firmware/config.txt || echo 'usb_max_current_enable=1' | sudo tee -a /boot/firmware/config.txt
grep -q 'blacklist btusb' /etc/modprobe.d/blacklist.conf || echo 'blacklist btusb' | sudo tee -a /etc/modprobe.d/blacklist.conf
cat /boot/firmware/config.txt

echo -e "\n [ Must reboot at this point ]\n"

###############################################
################## E N D ######################
###############################################
echo;echo -n "Ending in 3..";sleep 1;echo -n " 2..";sleep 1;echo " 1..";sleep 1;echo
