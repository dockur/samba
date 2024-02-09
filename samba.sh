#!/usr/bin/env bash
set -Eeuo pipefail

group="smb"
share="/storage"

id -u "$USER" &>/dev/null || adduser -S -D -H -h /tmp -s /sbin/nologin -G "$group" -g 'Samba User' "$USER" > /dev/null
echo -e "$PASS\n$PASS" | smbpasswd -a -s "$USER" > /dev/null

mkdir -p "$share"
chmod -R 0770 "$share"
chown "$USER:$group" "$share"

smbd --foreground --debug-stdout --debuglevel=10 --no-process-group
