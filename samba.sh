#!/usr/bin/env bash
set -Eeuo pipefail

SHARE="/storage"

mkdir -p "$SHARE"
chmod -R 777 "$SHARE"

smbd --foreground --log-stdout --no-process-group
