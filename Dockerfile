FROM alpine:latest

RUN apk add --no-cache bash

COPY copy.sh /copy.sh

ENTRYPOINT ["/copy.sh"]