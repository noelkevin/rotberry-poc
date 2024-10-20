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

