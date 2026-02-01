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

mkdir -m 777 -p /home/l/.msf4

echo -e "\n [ Stage compose ]\n"
sudo tee /home/l/docker-compose.yaml <<'EOF'
services:
  ms:
    image: metasploitframework/metasploit-framework:latest
    container_name: ms
    stdin_open: true
    tty: true
    restart: unless-stopped
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
    restart: unless-stopped
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

git clone https://github.com/lakinduakash/linux-wifi-hotspot /tmp/linux-wifi-hotspot || true
(cd /tmp/linux-wifi-hotspot/src/scripts && sudo make install-cli-only)

sudo sed -i 's/^    echo "ieee80211ax=1" >> $CONFDIR\/hostapd.conf$/    echo "ieee80211ax=1" >> $CONFDIR\/hostapd.conf ##80mhzband\
            echo "vht_oper_chwidth=1" >> $CONFDIR\/hostapd.conf\
            echo "vht_oper_centr_freq_seg0_idx=155" >> $CONFDIR\/hostapd.conf\
            echo "he_oper_chwidth=1" >> $CONFDIR\/hostapd.conf\
            echo "he_oper_centr_freq_seg0_idx=155" >> $CONFDIR\/hostapd.conf\
            echo "ieee80211w=1" >> $CONFDIR\/hostapd.conf\
            echo "beacon_int=100" >> $CONFDIR\/hostapd.conf\
            echo "dtim_period=2" >> $CONFDIR\/hostapd.conf\
            echo "skip_inactivity_poll=1" >> $CONFDIR\/hostapd.conf\
            echo "auth_algs=1" >> $CONFDIR\/hostapd.conf\
            echo "macaddr_acl=0" >> $CONFDIR\/hostapd.conf\
            echo "okc=1" >> $CONFDIR\/hostapd.conf\
            echo "wpa=2" >> $CONFDIR\/hostapd.conf\
            echo "rsn_pairwise=CCMP CCMP-256 GCMP GCMP-256" >> $CONFDIR\/hostapd.conf\
            echo "wpa_key_mgmt=WPA-PSK WPA-PSK-SHA256" >> $CONFDIR\/hostapd.conf\
            echo "ieee80211n=1" >> $CONFDIR\/hostapd.conf\
            echo "ieee80211ac=1" >> $CONFDIR\/hostapd.conf\
            echo "he_mu_edca_qos_info_param_count=0" >> $CONFDIR\/hostapd.conf\
            echo "he_mu_edca_qos_info_q_ack=0" >> $CONFDIR\/hostapd.conf\
            echo "he_mu_edca_qos_info_queue_request=0" >> $CONFDIR\/hostapd.conf\
            echo "he_mu_edca_qos_info_txop_request=0" >> $CONFDIR\/hostapd.conf\
            echo "he_mu_edca_ac_be_aifsn=8" >> $CONFDIR\/hostapd.conf\
            echo "he_mu_edca_ac_be_aci=0" >> $CONFDIR\/hostapd.conf\
            echo "he_mu_edca_ac_be_ecwmin=9" >> $CONFDIR\/hostapd.conf\
            echo "he_mu_edca_ac_be_ecwmax=10" >> $CONFDIR\/hostapd.conf\
            echo "he_mu_edca_ac_be_timer=255" >> $CONFDIR\/hostapd.conf\
            echo "he_mu_edca_ac_bk_aifsn=15" >> $CONFDIR\/hostapd.conf\
            echo "he_mu_edca_ac_bk_aci=1" >> $CONFDIR\/hostapd.conf\
            echo "he_mu_edca_ac_bk_ecwmin=9" >> $CONFDIR\/hostapd.conf\
            echo "he_mu_edca_ac_bk_ecwmax=10" >> $CONFDIR\/hostapd.conf\
            echo "he_mu_edca_ac_bk_timer=255" >> $CONFDIR\/hostapd.conf\
            echo "he_mu_edca_ac_vi_ecwmin=5" >> $CONFDIR\/hostapd.conf\
            echo "he_mu_edca_ac_vi_ecwmax=7" >> $CONFDIR\/hostapd.conf\
            echo "he_mu_edca_ac_vi_aifsn=5" >> $CONFDIR\/hostapd.conf\
            echo "he_mu_edca_ac_vi_aci=2" >> $CONFDIR\/hostapd.conf\
            echo "he_mu_edca_ac_vi_timer=255" >> $CONFDIR\/hostapd.conf\
            echo "he_mu_edca_ac_vo_aifsn=5" >> $CONFDIR\/hostapd.conf\
            echo "he_mu_edca_ac_vo_aci=3" >> $CONFDIR\/hostapd.conf\
            echo "he_mu_edca_ac_vo_ecwmin=5" >> $CONFDIR\/hostapd.conf\
            echo "he_mu_edca_ac_vo_ecwmax=7" >> $CONFDIR\/hostapd.conf\
            echo "he_mu_edca_ac_vo_timer=255" >> $CONFDIR\/hostapd.conf\
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
NO_VIRT=1
COUNTRY=US
FREQ_BAND=5
NEW_MACADDR=
DAEMONIZE=0
NO_HAVEGED=0
WIFI_IFACE=xwlan
INTERNET_IFACE=lo
SSID=AndroidAP
PASSPHRASE=rotberryrotberryrotberry
USE_PSK=0
EOF
sudo systemctl enable create_ap
sudo service create_ap start
sudo service create_ap restart;

echo -e "\n [ Stage Certs ]\n"
sudo openssl ecparam -name prime256v1 -genkey -noout -out self-ca.key
sudo openssl req -x509 -new -nodes -key self-ca.key -sha256 -days 3650 -out self-ca.crt \
  -subj "/C=US/ST=California/L=San Francisco/O=rotberry/OU=rotberry/CN=MacBook-Air.local"
sudo openssl ecparam -name prime256v1 -genkey -noout -out self-ssl.key
sudo openssl req -new -key self-ssl.key -out self-ssl.csr \
  -subj "/C=US/ST=California/L=San Francisco/O=rotberry/OU=rotberry/CN=MacBook-Air.local"
sudo tee extfile <<'EOF'
[ext]
subjectAltName = @alt_names

[alt_names]
DNS.1 = MacBook-Air.local
IP.1 = 192.168.12.1
IP.2 = 192.168.13.13
IP.3 = 192.168.13.14
IP.4 = 192.168.13.15
IP.5 = 192.168.15.15
IP.6 = 100.104.104.104
IP.7 = 100.105.105.105
EOF
sudo openssl x509 -req -in self-ssl.csr -CA self-ca.crt -CAkey self-ca.key -CAcreateserial \
  -out self-ssl.crt -days 365 -sha256 \
  -extfile extfile -extensions ext
sudo rm extfile

echo -e "\n [ Install Wondershaper ]\n"
git clone https://github.com/magnific0/wondershaper /tmp/wondershaper|| true
(cd /tmp/wondershaper && sudo make install)


echo -e "\n [ Stage Restic ]\n"
curl -o restic_0.18.0_linux_arm64.bz2 \
-L https://github.com/restic/restic/releases/download/v0.18.0/restic_0.18.0_linux_arm64.bz2 \
&& bzip2 --force -d restic_0.18.0_linux_arm64.bz2; 

sudo tee /home/l/restic.sh <<'EOF'
set -e
echo " [ STARTED:$(basename $BASH_SOURCE) ] "

#
#export BINRESTIC='./binrestic_0.18.0_darwin_arm64'
#export BINRESTIC='./binrestic_0.18.0_linux_amd64'
export BINRESTIC='./binrestic_0.18.0_linux_arm64'
#export BINRESTIC='./binrestic_0.18.0_windows_amd64.exe'
#

export BINRESTIC="$(realpath $BINRESTIC)"
$BINRESTIC version

function resticdiff() { #only in linux
  echo " [ start diffing repo:$1 ] "
  snapjson=$($BINRESTIC -r $1 snapshots --tag "1stcopy" --json)
  readarray -t short_pairs < <(echo $snapjson | jq -r 'sort_by(.time)|reverse|.[:4]|.[].short_id')
  printf '%s<<--' "${short_pairs[@]}"
  for ((i=0; i<${#short_pairs[@]}-1; i+=1)); do
      snap_a=${short_pairs[i]}
      snap_b=${short_pairs[i+1]}
      $BINRESTIC -r $1 diff $snap_b $snap_a --json | jq -r 'select(.message_type=="statistics") | "\n\n\(.target_snapshot)<<--\(.source_snapshot)\nFiles: \(.added.files) new, \(.removed.files) removed, \(.changed_files) changed\nDirs: \(.added.dirs) new, \(.removed.dirs) removed\nOthers: \(.added.others) new, \(.removed.others) removed\nData Blobs: \(.added.data_blobs) new, \(.removed.data_blobs) removed\nTree Blobs: \(.added.tree_blobs) new, \(.removed.tree_blobs) removed\n    Added: \(.added.bytes) bytes\n    Removed: \(.removed.bytes) bytes"'
  done
  echo " [ done diffing repo:$1 ] "
  sleep 5s
}

function resticmeta() {
  echo " [ start checking repo:$1 ] "
  $BINRESTIC -r $1 stats latest
  $BINRESTIC -r $1 snapshots
  $BINRESTIC -r $1 check
  echo " [ done checking repo:$1 ] "
}

function resticbackup() {
  echo " [ start backup repo:$1 from path:$2 ] "
  echo $BINRESTIC
  (cd $2; pwd; $BINRESTIC -r $1 backup .  -vv --tag 1stcopy)
  (cd $2; pwd; $BINRESTIC -r $1 backup .  -vv --tag 2ndcopy)
  echo " [ done backup repo:$1 from path:$2] "
}

###---------------###
### Input Section ###
###---------------###

read -rsp "tmppw: " tmppw
export RESTIC_PASSWORD=$tmppw
trap 'unset -v tmppw; unset -v RESTIC_PASSWORD; echo " [ FINISHED:$(basename $BASH_SOURCE) ] "' EXIT
echo 'RESTIC_PASSWORD set.'

###--------------###
### Main Section ###
###--------------###

## $BINRESTIC init --repo rotberry
#resticmeta "rest:https://192.168.15.15/rotberry  --insecure-tls"
#resticbackup "rest:https://192.168.15.15/rotberry --insecure-tls" /home/l

echo end
EOF

###############################################
################## E N D ######################
###############################################
echo;echo -n "Ending in 3..";sleep 1;echo -n " 2..";sleep 1;echo " 1..";sleep 1;echo
