FROM alpine:edge

RUN set -eu && \
    apk --no-cache add \
    tini \
    bash \
    samba \
    tzdata \
    shadow && \
    addgroup -S smb && \
    rm -f /etc/samba/smb.conf && \
    rm -rf /tmp/* /var/cache/apk/*

COPY --chmod=755 samba.sh /usr/bin/samba.sh
COPY --chmod=664 smb.conf /etc/samba/smb.default
COPY --chmod=600 users.conf /etc/samba/users.conf

VOLUME /storage
EXPOSE 139 445

HEALTHCHECK --interval=60s --timeout=15s CMD smbclient --configfile=/etc/samba.conf -L \\localhost -U % -m SMB3

ENTRYPOINT ["/sbin/tini", "--", "/usr/bin/samba.sh"]
