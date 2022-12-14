FROM alpine:latest

COPY copy.sh /copy.sh

ENTRYPOINT ["/copy.sh"]