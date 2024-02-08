#!/usr/bin/env bash
set -Eeuo pipefail

SHARE="/storage"

mkdir -p "$SHARE"
chmod -R 0770 "$SHARE"
chown samba:smb "$SHARE"

smbd --foreground --log-stdout --no-process-group
