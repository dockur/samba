#!/usr/bin/env bash
set -Eeuo pipefail

# Set variables for group and share directory
group="smb"
share="/storage"

# Check if the smb group exists, if not, create it
if ! getent group "$group" &>/dev/null; then
    groupadd "$group" || { echo "Failed to create group $group"; exit 1; }
fi

# Check if the user already exists, if not, create it
if ! id "$USER" &>/dev/null; then
    adduser -S -D -H -h /tmp -s /sbin/nologin -G "$group" -g 'Samba User' "$USER" || { echo "Failed to create user $USER"; exit 1; }
fi

# Get the current user and group IDs
OldUID=$(id -u "$USER")
OldGID=$(getent group "$group" | cut -d: -f3)

# Change the UID and GID of the user and group if necessary
if [[ "$OldUID" != "$UID" ]]; then
    usermod -u "$UID" "$USER" || { echo "Failed to change UID for $USER"; exit 1; }
fi

if [[ "$OldGID" != "$GID" ]]; then
    groupmod -g "$GID" "$group" || { echo "Failed to change GID for group $group"; exit 1; }
fi

# Change ownership of files and directories
find / -path "$share" -prune -o -group "$OldGID" -exec chgrp -h "$group" {} \;
find / -path "$share" -prune -o -user "$OldUID" -exec chown -h "$USER" {} \;

# Change Samba password
echo -e "$PASS\n$PASS" | smbpasswd -a -s "$USER" || { echo "Failed to change Samba password for $USER"; exit 1; }

# Update force user and force group in smb.conf
sed -i "s/^\(\s*\)force user =.*/\1force user = $USER/" "/etc/samba/smb.conf"
sed -i "s/^\(\s*\)force group =.*/\1force group = $group/" "/etc/samba/smb.conf"

# Verify if the RW variable is not equal to true (indicating read-only mode) and adjust settings accordingly
if [[ "$RW" != "true" ]]; then
    sed -i "s/^\(\s*\)writable =.*/\1writable = no/" "/etc/samba/smb.conf"
    sed -i "s/^\(\s*\)read only =.*/\1read only = yes/" "/etc/samba/smb.conf"
fi

# Create shared directory and set permissions
mkdir -p "$share" || { echo "Failed to create directory $share"; exit 1; }
chmod -R 0770 "$share" || { echo "Failed to set permissions for directory $share"; exit 1; }
chown -R "$USER:$group" "$share" || { echo "Failed to set ownership for directory $share"; exit 1; }

# Start the Samba daemon with the following options:
#  --foreground: Run in the foreground instead of daemonizing.
#  --debug-stdout: Send debug output to stdout.
#  --debuglevel=1: Set debug verbosity level to 1.
#  --no-process-group: Don't create a new process group for the daemon.
exec smbd --foreground --debug-stdout --debuglevel=1 --no-process-group
