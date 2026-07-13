# syntax=docker/dockerfile:1

FROM alpine:edge

RUN <<EOF
  set -eu

  apk update
  apk upgrade
  apk --no-cache add \
    tini \
    bash \
    samba \
    tzdata \
    shadow \
    libauth-samba

  # Create Samba group
  addgroup -S smb

  # Remove default Samba config
  rm -f /etc/samba/smb.conf

  rm -rf /tmp/* /var/cache/apk/*
EOF

COPY --chmod=755 samba.sh /usr/bin/samba.sh
COPY --chmod=664 smb.conf /etc/samba/smb.default

VOLUME /storage
EXPOSE 139 445

ENV NAME="Data"
ENV USER="samba"
ENV PASS="secret"

ENV UID=1000
ENV GID=1000
ENV RW=true

HEALTHCHECK --interval=60s --timeout=15s \
    CMD ["smbclient", "--configfile=/etc/samba.conf", "-L", "\\\\localhost", "-U", "%", "-m", "SMB3"]

ENTRYPOINT ["/sbin/tini", "--", "/usr/bin/samba.sh"]
