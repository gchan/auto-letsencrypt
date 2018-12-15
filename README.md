### gordonchan/auto-letsencrypt

[![](https://images.microbadger.com/badges/image/gordonchan/auto-letsencrypt.svg)](http://microbadger.com/images/gordonchan/auto-letsencrypt "Get your own image badge on microbadger.com")

A Docker image to automatically request and renew SSL/TLS certificates from [Let's Encrypt](https://letsencrypt.org/) using [certbot](https://certbot.eff.org/about/) and the [Webroot](https://certbot.eff.org/docs/using.html#webroot) method for domain validation. This image is also capable of sending a `HUP` signal to a Docker container running a web server in order to use the freshly minted certificates.

Based on the [quay.io/letsencrypt/letsencrypt](https://quay.io/repository/letsencrypt/letsencrypt) base image and inspired by [kvaps/letsencrypt-webroot](https://github.com/kvaps/docker-letsencrypt-webroot).

For ease of auditability, this version is simplified with configuration removed or generalized.

### Example Usage

As this image uses the webroot method, it assumes a web server is set up to serve ACME challenge files. For example, using Nginx:

```
location '/.well-known/acme-challenge' {
  root /var/www;
}
```

Your server container should be configured to be able use certificates retrieved by `certbot`. The certificates can be found at `/etc/letsencrypt/live/example.com` or be copied to a directory of your choice (see below). For example, using Nginx:

```
ssl_certificate     /etc/letsencrypt/live/example.com/fullchain.pem;
ssl_certificate_key /etc/letsencrypt/live/example.com/privkey.pem;
```

Run this image:

```
docker run -d
  -e 'DOMAINS=example.com www.example.com' \
  -e EMAIL=elliot@allsafe.com \
  -v /etc/letsencrypt:/etc/letsencrypt \
  -v /var/lib/letsencrypt:/var/lib/letsencrypt \
  -v /tmp/letsencrypt:/var/www \
  gordonchan/auto-letsencrypt
```

The container will attempt to request and renew SSL/TLS certificates for the specified domains and automatically repeat the renew process periodically (default is every 30 days).

#### Optional features

##### Reload server configuration
To automatically reload the server configuration to use the new certificates, provide the container name to the environment variable `SERVER_CONTAINER` and pass through the Docker socket to this container: `-v /var/run/docker.sock:/var/run/docker.sock`. The image will send a `HUP` signal to the specified container.

##### Copy certificates to another directory
Provide a directory path to the `CERTS_PATH` environment variable if you wish to copy the certificates to another directory. You may wish to do this in order to avoid exposing the entire `/etc/letsencrypt/` directory to your web server container.

##### Customize webroot path
To configure the webroot path use the `WEBROOT_PATH` environment variable. The default is `/var/www`.

##### Change the check frequency
Provide a number to the `CHECK_FREQ` environment variable to adjust how often it attempts to renew a certificate. The default is 30 days. Please note `certbot` is configured to keep matching certificates until one is due for renewal.

#### An example using all of the features

```
docker run -d
  -e 'DOMAINS=example.com www.example.com' \
  -e EMAIL=elliot@allsafe.com \
  -e NGINX_CONTAINER=nginx \
  -e SERVER_CONTAINER=nginx \
  -e CERTS_PATH=/etc/nginx/certs \
  -e WEBROOT_PATH=/var/www \
  -e CHECK_FREQ=7 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /etc/letsencrypt:/etc/letsencrypt \
  -v /var/lib/letsencrypt:/var/lib/letsencrypt \
  -v /tmp/letsencrypt:/var/www \
  -v /etc/nginx/certs:/etc/nginx/certs \
  gordonchan/auto-letsencrypt
```

#### An example using Docker Compose

```
version: '2'

services:
  server:
    container_name: server
    image: gordonchan/nginx-ssl-ghost
    volumes:
      - certs:/etc/nginx/certs
      - /tmp/letsencrypt/www:/tmp/letsencrypt/www
    links:
      - app:ghost
    ports:
      - "80:80"
      - "443:443"
    restart: unless-stopped

  letsencrypt:
    container_name: server
    image: gordonchan/auto-letsencrypt
    links:
      - server
    volumes:
      - /var/log/letsencrypt/:/var/log/letsencrypt
      - /var/run/docker.sock:/var/run/docker.sock
      - /etc/letsencrypt:/etc/letsencrypt
      - /var/lib/letsencrypt:/var/lib/letsencrypt
      - /tmp/letsencrypt/www:/tmp/letsencrypt/www
      - certs:/etc/nginx/certs
    environment:
      - EMAIL=elliot@allsafe.com
      - SERVER_CONTAINER=server
      - WEBROOT_PATH=/tmp/letsencrypt/www
      - CERTS_PATH=/etc/nginx/certs
      - DOMAINS=e-corp-usa.com www.e-corp-usa.com
      - CHECK_FREQ=7
    restart: unless-stopped

  volumes:
    certs:
```

#### Environment variables

* **DOMAINS**: Domains for your certificate. e.g. `example.com www.example.com`.
* **EMAIL**: Email for urgent notices and lost key recovery. e.g. `your@email.tld`.
* **WEBROOT_PATH** Path to the letsencrypt directory in the web server for checks. Defaults to `/var/www`.
* **CERTS_PATH**: Optional. Copy the new certificates to the specified path. e.g. `/etc/nginx/certs`.
* **SERVER_CONTAINER**: Optional. The Docker container name of the server you wish to send a `HUP` signal to in order to reload its configuration and use the new certificates.
* **SERVER_CONTAINER_LABEL**: Optional. The Docker container label of the server you wish to send a `HUP` signal to in order to reload its configuration and use the new certificates. This environment variable will be helpfull in case of deploying with docker swarm since docker swarm will create container name itself.
* **CHECK_FREQ**: How often (in days) to perform checks. Defaults to `30`.

#### License

Copyright (c) 2016 Gordon Chan. Released under the MIT License. It is free software, and may be redistributed under the terms specified in the [LICENSE](https://github.com/gchan/dockerfiles/blob/master/LICENSE.txt) file.

[![Analytics](https://ga-beacon.appspot.com/UA-70790190-2/dockerfiles/auto-letsencrypt/README.md?flat)](https://github.com/igrigorik/ga-beacon)

