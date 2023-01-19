FROM certbot/certbot:v2.1.1

RUN apk update && apk add --no-cache docker-cli bash
ADD entrypoint.sh .

ENTRYPOINT [ "./entrypoint.sh" ]
