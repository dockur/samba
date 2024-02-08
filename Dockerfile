FROM alpine:edge

RUN apk --no-cache add \
  tini \
  bash \
  samba \
  tzdata \
  && rm -rf /var/cache/apk/*
  
COPY smb.conf /etc/samba/smb.conf

COPY samba.sh /usr/bin/
RUN chmod +x /usr/bin/samba.sh

VOLUME /storage
EXPOSE 137/udp 138/udp 139 445

HEALTHCHECK --interval=60s --timeout=15s CMD smbclient -L \\localhost -U % -m SMB3

ENTRYPOINT ["/sbin/tini", "--", "/usr/bin/samba.sh"]
