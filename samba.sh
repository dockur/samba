#!/usr/bin/env bash
set -Eeuo pipefail

share="/storage"

mkdir -p "$share"
chmod -R 0770 "$share"
chown samba:smb "$share"

pass="secret"
username="samba"
echo -e "$pass\n$pass" | smbpasswd -a -s $username

smbd --foreground --log-stdout --no-process-group
