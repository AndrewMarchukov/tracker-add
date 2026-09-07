FROM alpine:3.24.1

ENV TORRENTLIST=https://raw.githubusercontent.com/ngosang/trackerslist/master/trackers_all.txt

COPY ./tracker-add-docker.sh /opt/tracker-add-docker.sh

RUN apk add --update \
        bash transmission-cli curl coreutils && \
        rm -rf /var/cache/apk/* && \
        chmod +x /opt/tracker-add-docker.sh

USER guest
ENTRYPOINT [ "/opt/tracker-add-docker.sh" ]
