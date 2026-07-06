#!/usr/bin/env bash
set -Eeuo pipefail

: "${FORCE:="Y"}"    # Add force user and force group settings to config
: "${CLEAR:="Y"}"    # Overwrite passwords for existing users during startup

set_password() {
    local cfg="$1"
    local username="$2"
    local password="$3"
    local add="${4:-}"

    if [ "$add" = "add" ]; then
        printf '%s\n%s\n' "$password" "$password" | smbpasswd -a -c "$cfg" -s "$username" || return 1
    else
        printf '%s\n%s\n' "$password" "$password" | smbpasswd -c "$cfg" -s "$username" || return 1
    fi

    return 0
}

user_exists() {
    local cfg="$1"
    local username="$2"
    local pdb_output

    pdb_output=$(pdbedit -s "$cfg" -L)
    printf '%s\n' "$pdb_output" | cut -d: -f1 | grep -Fxq "$username"
}

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
    local homedir="$7"

    local groups="$groupname"
    [[ "$groups" != "smb" ]] && groups+=",smb"

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
        local extra_args=()
        # Check if home directory already exists, if so do not create home during user creation
        if [ -d "$homedir" ]; then
          extra_args=("${extra_args[@]}" -H)
        fi
        adduser "${extra_args[@]}" -S -D -h "$homedir" -s /sbin/nologin -G "$groupname" -u "$uid" -g "Samba User" "$username" || { echo "Failed to create user $username"; return 1; }
    else
        # Check if the uid right,if not, change it
        local current_uid
        current_uid=$(id -u "$username")
        if [[ "$current_uid" != "$uid" ]]; then
            echo "User $username exists but UID differs, updating UID..."
            usermod -o -u "$uid" "$username" > /dev/null || { echo "Failed to update UID for user $username"; return 1; }
        fi
    fi

    # Update user's group
    usermod -a -G "$groups" "$username" > /dev/null || { echo "Failed to update group for user $username"; return 1; }

    # Check if the user is a samba user
    if user_exists "$cfg" "$username"; then
        # skip samba password update if password is empty, * or !
        if [[ -n "$password" && "$password" != "*" && "$password" != "!" && "$CLEAR" == [Yy1]* ]]; then
            # If the user is a samba user, update its password in case it changed
            set_password "$cfg" "$username" "$password" > /dev/null || { echo "Failed to update Samba password for $username"; return 1; }
        fi
    else
        if [[ -z "$password" ]]; then
            # If no password is provided, add the user with a disabled password (guest/no-login)
            smbpasswd -a -n -c "$cfg" -s "$username" > /dev/null || { echo "Failed to add Samba user $username"; return 1; }
            smbpasswd -d -c "$cfg" -s "$username" > /dev/null || { echo "Failed to disable Samba user $username"; return 1; }
            [[ "$username" != "$USER" ]] && echo "User $username has been added to Samba with no password (guest account)."
        else
            # If the user is not a samba user, create it and set a password
            set_password "$cfg" "$username" "$password" add > /dev/null || { echo "Failed to add Samba user $username"; return 1; }
            [[ "$username" != "$USER" ]] && echo "User $username has been added to Samba and password set."
        fi
    fi
    
    return 0
}

escape() {
    printf '%s' "$1" | sed 's/[\/&\\]/\\&/g'
}

# Create directories if missing
mkdir -p /var/lib/samba/sysvol || :
mkdir -p /var/lib/samba/private || :
mkdir -p /var/lib/samba/bind-dns || :

# Set variables for group and share directory
group="smb"
share="/storage"
secret="/run/secrets/pass"
config="/etc/samba/smb.conf"
users="/etc/samba/users.conf"

# Check if the secret file exists and if its size is greater than zero
if [ -s "$secret" ]; then
    PASS=$(cat "$secret")
fi

# Check if config file is not a directory
if [ -d "$config" ]; then
    echo "The bind $config maps to a file that does not exist!"
    exit 1
fi

# Check if users file is not a directory
if [ -d "$users" ]; then
    echo "The bind $users maps to a file that does not exist!"
    exit 1
fi

# Create shared directory
mkdir -p "$share" || { echo "Failed to create directory $share"; exit 1; }

# Set permissions for share directory if new (empty), leave untouched if otherwise
if [ -z "$(ls -A "$share")" ]; then
    chmod 0770 "$share" || echo "Failed to set permissions for directory $share"
fi

# Check if an external config file was supplied
if [ -s "$config" ]; then

    # Inform the user we are using a custom configuration file.
    echo "Using provided configuration file: $config."

else

    config="/etc/samba/smb.tmp"
    template="/etc/samba/smb.default"

    if [ ! -f "$template" ]; then
        echo "Your /etc/samba directory does not contain a valid smb.conf file!"
        exit 1
    fi

    # Generate a config file from template
    rm -f "$config"
    cp "$template" "$config"

    # Set custom display name if provided
    if [ -n "$NAME" ] && [[ "${NAME,,}" != "data" ]]; then
        name_escaped="$(escape "$NAME")"
        sed -i "s/\[Data\]/\[$name_escaped\]/" "$config"
    fi

    # Verify if the RW variable is equal to false (indicating read-only mode) 
    if [[ "$RW" == [Ff0]* ]]; then
        # Adjust settings in smb.conf to set share to read-only
        sed -i "s/^\(\s*\)writable =.*/\1writable = no/" "$config"
        sed -i "s/^\(\s*\)read only =.*/\1read only = yes/" "$config"
    fi

    # Check if multi-user mode is enabled
    if [ ! -s "$users" ] && [[ "$FORCE" == [Yy1]* ]]; then
        # Add force user settings
        { echo "   "; echo "   force user = $USER"; echo "   force group = $group"; } >> "$config"
    fi

fi

# Check if multi-user mode is enabled
if [ ! -s "$users" ]; then

    add_user "$config" "$USER" "$UID" "$group" "$GID" "$PASS" "$share" || { echo "Failed to add user $USER"; exit 1; }

else

    while IFS= read -r line || [[ -n ${line} ]]; do

        # Skip lines that are comments or empty
        [[ "$line" =~ ^#.*$ || -z "$line" ]] && continue

        if [ "$(awk -F: '{print NF}' <<< "$line")" -gt 6 ]; then
            echo "Skipping line with unsupported ':' in password/home field: $line"
            continue
        fi

        # Split each line by colon and assign to variables
        IFS=':' read -r username uid groupname gid password homedir <<< "$line"

        # Check if all required fields are present
        if [[ -z "$username" || -z "$uid" || -z "$groupname" || -z "$gid" ]]; then
            echo "Skipping incomplete line: $line"
            continue
        fi

        # Default homedir if not explicitly set for user
        [[ -z "$homedir" ]] && homedir="$share"

        # Call the function with extracted values
        add_user "$config" "$username" "$uid" "$groupname" "$gid" "$password" "$homedir" || { echo "Failed to add user $username"; exit 1; }

    done < <(tr -d '\r' < "$users")

fi

# Set permissions for share directory if new (empty), leave untouched if otherwise
if [ -z "$(ls -A "$share")" ] && [ ! -s "$users" ]; then
    chown "$USER:$group" "$share" || echo "Failed to set ownership for directory $share"
fi

# Store configuration location for Healthcheck
ln -sf "$config" /etc/samba.conf

# Set directory permissions
[ -d /run/samba/msg.lock ] && chmod -R 0755 /run/samba/msg.lock || :
[ -d /var/log/samba/cores ] && chmod -R 0700 /var/log/samba/cores || :
[ -d /var/cache/samba/msg.lock ] && chmod -R 0755 /var/cache/samba/msg.lock || :

# Start the Samba daemon with the following options:
#  --configfile: Location of the configuration file.
#  --foreground: Run in the foreground instead of daemonizing.
#  --debug-stdout: Send debug output to stdout.
#  --debuglevel=1: Set debug verbosity level to 1.
#  --no-process-group: Don't create a new process group for the daemon.
exec smbd --configfile="$config" --foreground --debug-stdout -d "${DEBUG_LEVEL:-1}" --no-process-group
