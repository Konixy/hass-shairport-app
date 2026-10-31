FROM mikebrady/shairport-sync:latest

RUN apk add --no-cache jq alsa-plugins-pulse

COPY start-addon.sh /start-addon.sh
COPY run-addon.sh /run-addon.sh
RUN chmod +x /start-addon.sh /run-addon.sh

COPY shairport-sync.conf.tpl /etc/shairport-sync.conf.tpl

ENTRYPOINT ["/start-addon.sh"]
