#!/usr/bin/env bash
set -Eeuo pipefail

group="smb"

adduser -S -D -H -h /tmp -s /sbin/nologin -G "$group" -g 'Samba User' "$USER" && \
echo -e "$PASS\n$PASS" | smbpasswd -a -s "$USER"

share="/storage"
mkdir -p "$share"
chmod -R 0770 "$share"
chown "$USER:$group" "$share"

smbd --foreground --debug-stdout --no-process-group
