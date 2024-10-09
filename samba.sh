#!/usr/bin/env bash
set -Eeuo pipefail

# This function checks for the existence of a specified Samba user and group. If the user does not exist, 
# it creates a new user with the provided username, user ID (UID), group name, group ID (GID), and password. 
# If the user already exists, it updates the user's UID and group association as necessary, 
# and updates the password in the Samba database. The function ensures that the group also exists, 
# creating it if necessary, and modifies the group ID if it differs from the provided value.
add_user() {
    local cfg="$1"
    local username="$2"
    local uid="$3"
    local groupname="$4"
    local gid="$5"
    local password="$6"

    # Check if the smb group exists, if not, create it
    if ! getent group "$groupname" &>/dev/null; then
        [[ "$groupname" != "smb" ]] && echo "Group $groupname does not exist, creating group..."
        groupadd -o -g "$gid" "$groupname" > /dev/null || { echo "Failed to create group $groupname"; return 1; }
    else
        # Check if the gid right,if not, change it
        local current_gid
        current_gid=$(getent group "$groupname" | cut -d: -f3)
        if [[ "$current_gid" != "$gid" ]]; then
            [[ "$groupname" != "smb" ]] && echo "Group $groupname exists but GID differs, updating GID..."
            groupmod -o -g "$gid" "$groupname" > /dev/null || { echo "Failed to update GID for group $groupname"; return 1; }
        fi
    fi

    # Check if the user already exists, if not, create it
    if ! id "$username" &>/dev/null; then
        [[ "$username" != "$USER" ]] && echo "User $username does not exist, creating user..."
        adduser -S -D -H -h /tmp -s /sbin/nologin -G "$groupname" -u "$uid" -g "Samba User" "$username" || { echo "Failed to create user $username"; return 1; }
    else
        # Check if the uid right,if not, change it
        local current_uid
        current_uid=$(id -u "$username")
        if [[ "$current_uid" != "$uid" ]]; then
            echo "User $username exists but UID differs, updating UID..."
            usermod -o -u "$uid" "$username" > /dev/null || { echo "Failed to update UID for user $username"; return 1; }
        fi

        # Update user's group
        usermod -g "$groupname" "$username" > /dev/null || { echo "Failed to update group for user $username"; return 1; }
    fi

    # Check if the user is a samba user
    if pdbedit -s "$cfg" -L | grep -q "^$username:"; then
        # If the user is a samba user, change its password
        echo -e "$password\n$password" | smbpasswd -c "$cfg" -s "$username" > /dev/null || { echo "Failed to update Samba password for $username"; return 1; }
        [[ "$username" != "$USER" ]] && echo "Password for existing Samba user $username has been updated."
    else
        # If the user is not a samba user, create it and set a password
        echo -e "$password\n$password" | smbpasswd -a -c "$cfg" -s "$username" > /dev/null || { echo "Failed to add Samba user $username"; return 1; }
        [[ "$username" != "$USER" ]] && echo "User $username has been added to Samba and password set."
    fi

    return 0
}

# Set variables for group and share directory
group="smb"
share="/storage"
secret="/run/secrets/pass"
config="/etc/samba/smb.conf"
user_config="/etc/samba/smb_user.conf"

# Create shared directory
mkdir -p "$share" || { echo "Failed to create directory $share"; exit 1; }

# Check if the secret file exists and if its size is greater than zero
if [ -s "$secret" ]; then
    PASS=$(cat "$secret")
fi

if [ -f "$config" ]; then

    # Inform the user we are using a custom configuration file.
    echo "Using provided configuration file: $config."

else

    config="/etc/samba/smb.tmp"
    template="/etc/samba/smb.default"

    # Generate a config file from template
    rm -f "$config"
    cp "$template" "$config"

    # Update force user and force group in smb.conf
    sed -i "s/^\(\s*\)force user =.*/\1force user = $USER/" "$config"
    sed -i "s/^\(\s*\)force group =.*/\1force group = $group/" "$config"

    # Verify if the RW variable is equal to false (indicating read-only mode) 
    if [[ "$RW" == [Ff0]* ]]; then
        # Adjust settings in smb.conf to set share to read-only
        sed -i "s/^\(\s*\)writable =.*/\1writable = no/" "$config"
        sed -i "s/^\(\s*\)read only =.*/\1read only = yes/" "$config"
    fi

fi

# Check if multi-user mode is enabled
if [[ -f "$user_config" ]]; then

    while read -r line; do

        # Skip lines that are comments or empty
        [[ "$line" =~ ^#.*$ || -z "$line" ]] && continue

        # Split each line by colon and assign to variables
        username=$(echo "$line" | cut -d':' -f1)
        uid=$(echo "$line" | cut -d':' -f2)
        groupname=$(echo "$line" | cut -d':' -f3)
        gid=$(echo "$line" | cut -d':' -f4)
        password=$(echo "$line" | cut -d':' -f5)

        # Check if all required fields are present
        if [[ -z "$username" || -z "$uid" || -z "$groupname" || -z "$gid" || -z "$password" ]]; then
            echo "Skipping incomplete line: $line"
            continue
        fi

        # Call the function with extracted values
        add_user "$config" "$username" "$uid" "$groupname" "$gid" "$password"

    done < "$user_config"

else

    add_user "$config" "$USER" "$UID" "$group" "$GID" "$PASS"

    if [[ "$RW" != [Ff0]* ]]; then
        # Set permissions for share directory if new (empty), leave untouched if otherwise
        if [ -z "$(ls -A "$share")" ]; then
            chmod 0770 "$share" || { echo "Failed to set permissions for directory $share"; exit 1; }
            chown "$USER:$group" "$share" || { echo "Failed to set ownership for directory $share"; exit 1; }
        fi
    fi

fi

# Start the Samba daemon with the following options:
#  --foreground: Run in the foreground instead of daemonizing.
#  --debug-stdout: Send debug output to stdout.
#  --debuglevel=1: Set debug verbosity level to 1.
#  --no-process-group: Don't create a new process group for the daemon.
exec smbd --configfile="$config" --foreground --debug-stdout --debuglevel=1 --no-process-group
