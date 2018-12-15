#!/bin/bash

trap "exit" SIGHUP SIGINT SIGTERM

if [ -z "$DOMAINS" ] ; then
  echo "No domains set, please fill -e 'DOMAINS=example.com www.example.com'"
  exit 1
fi

if [ -z "$EMAIL" ] ; then
  echo "No email set, please fill -e 'EMAIL=your@email.tld'"
  exit 1
fi

DOMAINS=(${DOMAINS})
CERTBOT_DOMAINS=("${DOMAINS[*]/#/--domain }")
CHECK_FREQ="${CHECK_FREQ:-30}"
WEBROOT_PATH="${WEBROOT_PATH:-"/var/www"}"

check() {
  echo "* Starting webroot initial certificate request script..."

  certbot certonly --webroot --agree-tos --noninteractive --text --expand \
      --email ${EMAIL} \
      --webroot-path ${WEBROOT_PATH} \
      ${CERTBOT_DOMAINS}

  echo "* Certificate request process finished for domain $DOMAINS"

  if [ "$CERTS_PATH" ] ; then
    echo "* Copying certificates to $CERTS_PATH"
    eval cp /etc/letsencrypt/live/$DOMAINS/* $CERTS_PATH/
  fi

  if [ "$SERVER_CONTAINER" ]; then
    echo "* Reloading Nginx configuration on $SERVER_CONTAINER"
    eval docker kill -s HUP $SERVER_CONTAINER
  fi

  if [ "$SERVER_CONTAINER_LABEL" ]; then
    echo "* Reloading Nginx configuration for label $SERVER_CONTAINER_LABEL"

    container_id=`docker ps --filter label=$SERVER_CONTAINER_LABEL -q`
    eval docker kill -s HUP $container_id
  fi

  echo "* Next check in $CHECK_FREQ days"
  sleep ${CHECK_FREQ}d
  check
}

check
