FROM alpine:edge

RUN apk --no-cache add \
  tini \
  bash \
  samba \
  tzdata \
  shadow && \
  addgroup -S smb && \
  rm -rf /tmp/* /var/cache/apk/*
  
COPY smb.conf /etc/samba/smb.conf

COPY samba.sh /usr/bin/
RUN chmod +x /usr/bin/samba.sh

VOLUME /storage
EXPOSE 139 445

ENV USER "samba"
ENV PASS "secret"
ENV UID 1000
ENV GID 1000
ENV RW true
ENV CONFIG "builtin"

HEALTHCHECK --interval=60s --timeout=15s CMD smbclient -L \\localhost -U % -m SMB3

ENTRYPOINT ["/sbin/tini", "--", "/usr/bin/samba.sh"]
