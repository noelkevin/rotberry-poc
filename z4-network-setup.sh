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

echo -e "\n [ Write drivers into tmp ]\n"
cat << 'EOF' > /tmp/mt7921au.tar.gz.b64
EOF
ls -lah /tmp/mt7921au.tar.gz.b64
echo -e "\n [ Decrypt drivers ]\n"
base64 -d /tmp/mt7921au.tar.gz.b64 > /tmp/mt7921au.tar.gz
tar -xzf /tmp/mt7921au.tar.gz -C /tmp
ls -lah /tmp/mt7921au

echo -e "\n [ Replace drivers ]\n"
sudo cp /tmp/mt7921au/WIFI_MT7961_patch_mcu_1_2_hdr.bin /lib/firmware/mediatek/WIFI_MT7961_patch_mcu_1_2_hdr.bin
sudo cp /tmp/mt7921au/BT_RAM_CODE_MT7961_1_2_hdr.bin /lib/firmware/mediatek/BT_RAM_CODE_MT7961_1_2_hdr.bin
sudo cp /tmp/mt7921au/WIFI_RAM_CODE_MT7961_1.bin /lib/firmware/mediatek/WIFI_RAM_CODE_MT7961_1.bin
ls -lah /lib/firmware/mediatek/*.bin

echo -e "\n [ Mac Spoofing for wifi interfaces ]\n"
sudo tee /etc/systemd/network/01-mac-wlan0.link <<'EOF'
[Match]
PermanentMACAddress=d8:3a:dd:1d:be:45

[Link]
MACAddressPolicy=random
EOF
sudo tee /etc/systemd/network/02-mac-wlancomfast.link <<'EOF'
[Match]
PermanentMACAddress=e0:e1:a9:36:4d:7b

[Link]
MACAddressPolicy=random
EOF
sudo tee /etc/systemd/network/03-mac-wlangear.link <<'EOF'
[Match]
PermanentMACAddress=d6:dc:1d:13:c6:e7

[Link]
MACAddressPolicy=random
EOF

echo -e "\n [ Rename wifi interfaces ]\n"
sudo tee /etc/udev/rules.d/70-persistent-net.rules <<'EOF'
SUBSYSTEM=="net", ACTION=="add", ATTRS{idVendor}=="0e8d", ATTRS{idProduct}=="7961" NAME="wlancomfast"
SUBSYSTEM=="net", ACTION=="add", ATTRS{idVendor}=="0846", ATTRS{idProduct}=="9060" NAME="wlangear"
EOF

echo -e "\n [ Disable scatter-gather, btusb conf ]\n"
sudo tee /etc/modprobe.d/mt76_usb_disablesg.conf <<'EOF'
options mt76_usb disable_usb_sg=1
options mt76_usb ps_enable=0
EOF
sudo tee /etc/modprobe.d/btusb.conf <<'EOF'
options btusb reset=N
EOF

echo -e "\n [ Reload drivers and apply changes ]\n"
sudo rmmod  mt7921u
sudo modprobe mt7921u
sudo udevadm control --reload-rules
sudo udevadm trigger
sudo systemctl restart systemd-networkd
ip a

if [ ! -f "/etc/netplan/50-cloud-init.yaml.ori" ]; then
echo -e "\n [ Netplan Backup as 50-cloud-init.yaml.ori ]\n"
sudo cp /etc/netplan/50-cloud-init.yaml /etc/netplan/50-cloud-init.yaml.ori
else
echo -e "\n [ Skipping netplan backup, already exists ]\n"
fi

echo -e "\n [ Revert Netplan before adjusting ]\n"
sudo cp /etc/netplan/50-cloud-init.yaml.ori /etc/netplan/50-cloud-init.yaml

echo -e "\n [ Adjust ethernet ]\n"
sudo tee /tmp/eth-init.yaml <<'EOF'
network:
#    bonds:
#        bond0:
#            interfaces:
#                - wlan0
#                - wlangear
#            dhcp4: true
#            parameters:
#                mode: active-backup
#                primary: wlangear
    ethernets:
        eth0:
            match:
                macaddress: d8:3a:dd:1d:be:43
            dhcp4: false
            addresses:
                - 192.168.13.13/24
            optional: false
        usb0:
            dhcp4: false
            addresses:
                - 192.168.15.15/24
            optional: false
EOF
sudo cp /etc/netplan/50-cloud-init.yaml /etc/netplan/50-cloud-init.yaml.tmp
sudo yq -y -s '.[0] * .[1]' /tmp/eth-init.yaml /etc/netplan/50-cloud-init.yaml.tmp | sudo tee /etc/netplan/50-cloud-init.yaml
sudo rm /etc/netplan/50-cloud-init.yaml.tmp

#echo -e "\n [ Adjust wifi ]\n"
#sudo yq -y -i '.network.wifis.wlan0 as $x | .network.wifis.wlangear = $x ' /etc/netplan/50-cloud-init.yaml
#sudo yq -y -i 'del(.network.wifis.wlan0)' /etc/netplan/50-cloud-init.yaml
#sudo cat /etc/netplan/50-cloud-init.yaml

echo -e "\n [ Apply Netplan ]\n"
sudo netplan apply; sudo systemctl restart avahi-daemon
#cat /proc/net/bonding/bond0

echo -e "\n [ Enable avahi reflection ]\n"
sudo sed -r -i 's/#?enable-reflector=no/enable-reflector=yes/g' /etc/avahi/avahi-daemon.conf
sudo sed -r -i 's/#?allow-interfaces.*/allow-interfaces=bond0,wlan0,usb0,eth0,wlancomfast,wlangear,ap0/g' /etc/avahi/avahi-daemon.conf
sudo systemctl enable avahi-daemon.service
sudo systemctl restart avahi-daemon.service

#echo -e "\n [ Put led to show bond0 status ]\n"
#sudo tee /usr/local/bin/check_bond0.sh <<'EOF'
##!/bin/bash
#RLED_PATH="/sys/class/leds/PWR/brightness"
#GLED_PATH="/sys/class/leds/ACT/brightness"
#RLED_TRIG="/sys/class/leds/PWR/trigger"
#GLED_TRIG="/sys/class/leds/ACT/trigger"
#while true; do
#    if ip link show bond0 | grep -q "state UP"; then
#     if (iw dev wlangear link | grep -q "Connected" || iw dev wlancomfast link | grep -q "Connected"); then
#            echo none > "$RLED_TRIG"
#            sleep 15
#        else
#                for i in $(seq 1 40);
#                do
#                    echo 1 > "$RLED_PATH";sleep 0.05;echo 0 > "$RLED_PATH";sleep 0.05;
#                    echo 1 > "$RLED_PATH";sleep 0.05;echo 0 > "$RLED_PATH";sleep 0.05;
#                    echo 1 > "$RLED_PATH";sleep 0.05;echo 0 > "$RLED_PATH";sleep 0.5;
#                done
#     fi
#    else
#            echo heartbeat > "$RLED_TRIG"
#            sleep 15
#    fi
#done
#EOF
#sudo tee /etc/systemd/system/check_bond0.service <<'EOF'
#[Unit]
#Description=Check bond0 Interface and Control LED
#
#[Service]
#ExecStart=/usr/local/bin/check_bond0.sh
#Restart=always
#User=root
#
#[Install]
#WantedBy=multi-user.target
#EOF
#sudo systemctl daemon-reload
#sudo systemctl enable check_bond0.service
#sudo systemctl restart check_bond0.service

###############################################
################## E N D ######################
###############################################
echo;echo -n "Ending in 3..";sleep 1;echo -n " 2..";sleep 1;echo " 1..";sleep 1;echo