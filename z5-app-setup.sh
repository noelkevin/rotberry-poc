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

mkdir -m 777 -p /home/l/.msf4

echo -e "\n [ Stage compose ]\n"
sudo tee /home/l/docker-compose.yaml <<'EOF'
services:
  ms:
    image: metasploitframework/metasploit-framework:latest
    container_name: ms
    stdin_open: true
    tty: true
    restart: always
    depends_on:
      - db
    networks:
      - inet
      - nonet
    ports:
      - 4444:4444
    environment:
      DATABASE_URL: postgres://postgres:postgres@db:5432/msf
    volumes:
      - .msf4:/home/msf/.msf4
  db:
    image: postgres:11-alpine
    container_name: db
    restart: always
    networks:
      - nonet
    environment:
      POSTGRES_DB: msf
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
    volumes:
      - pgdata:/var/lib/postgresql
volumes:
  pgdata:
    driver: local
    name: pgdata
networks:
  inet:
    name: inet
  nonet:
    name: nonet
    driver: bridge
    internal: true
EOF

sudo docker compose up -d

git clone https://github.com/lakinduakash/linux-wifi-hotspot /tmp/linux-wifi-hotspot;
cd /tmp/linux-wifi-hotspot/src/scripts && sudo make install-cli-only

sudo sed -i 's/^    echo "ieee80211ax=1" >> $CONFDIR\/hostapd.conf$/    echo "ieee80211ax=1" >> $CONFDIR\/hostapd.conf ##80mhzband\
            echo "vht_oper_chwidth=1" >> $CONFDIR\/hostapd.conf\
            echo "vht_oper_centr_freq_seg0_idx=155" >> $CONFDIR\/hostapd.conf\
            echo "ieee80211w=1" >> $CONFDIR\/hostapd.conf\
            echo "tx_queue_data2_burst=2.0" >> $CONFDIR\/hostapd.conf\
            echo "uapsd_advertisement_enabled=1" >> $CONFDIR\/hostapd.conf\
            echo "utf8_ssid=1" >> $CONFDIR\/hostapd.conf\
            echo "multi_ap=0" >> $CONFDIR\/hostapd.conf\
            echo "bss_load_update_period=60" >> $CONFDIR\/hostapd.conf\
            echo "chan_util_avg_period=600" >> $CONFDIR\/hostapd.conf\
            echo "disassoc_low_ack=0" >> $CONFDIR\/hostapd.conf\
            echo "skip_inactivity_poll=1" >> $CONFDIR\/hostapd.conf\
            echo "preamble=1" >> $CONFDIR\/hostapd.conf\
            echo "auth_algs=3" >> $CONFDIR\/hostapd.conf\
            echo "okc=1" >> $CONFDIR\/hostapd.conf\
            echo "wmm_enabled=1" >> $CONFDIR\/hostapd.conf/' /usr/bin/create_ap

sudo tee /etc/create_ap.conf <<'EOF'
CHANNEL=149
WPA_VERSION=2
ETC_HOSTS=1
DHCP_DNS=gateway
NO_DNS=0
NO_DNSMASQ=0
HIDDEN=0
MAC_FILTER=0
MAC_FILTER_ACCEPT=/etc/hostapd/hostapd.accept
ISOLATE_CLIENTS=0
SHARE_METHOD=nat
IEEE80211N=1
IEEE80211AC=1
IEEE80211AX=1
HT_CAPAB=[LDPC][HT40+][HT40-][GF][SHORT-GI-20][SHORT-GI-40][TX-STBC][RX-STBC1][MAX-AMSDU-7935]
VHT_CAPAB=[RXLDPC][SHORT-GI-80][TX-STBC-2BY1][SU-BEAMFORMEE][MU-BEAMFORMEE][RX-ANTENNA-PATTERN][TX-ANTENNA-PATTERN][RX-STBC-1][BF-ANTENNA-4][MAX-MPDU-11454][MAX-A-MPDU-LEN-EXP7]
DRIVER=nl80211
NO_VIRT=0
COUNTRY=US
FREQ_BAND=5
NEW_MACADDR=
DAEMONIZE=0
NO_HAVEGED=0
WIFI_IFACE=wlangear
INTERNET_IFACE=lo
SSID=AndroidAP
PASSPHRASE=rotberryrotberryrotberry
USE_PSK=0
EOF
sudo systemctl enable create_ap
sudo service create_ap start
sudo service create_ap restart;


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

