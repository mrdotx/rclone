#!/bin/sh

# path:       /home/klassiker/.local/share/repos/rclone/sync_keepass.sh
# author:     klassiker [mrdotx]
# github:     https://github.com/mrdotx/rclone
# date:       2020-06-08T12:00:43+0200

rclone_name="dropbox"
keepass_file="klassiker.kdbx"
keepass_local="$HOME/.local/share/cloud/dropbox/KeePass/"
keepass_remote="/KeePass"

# assemble full path to local and remote files
keepass_local_path="$keepass_local/$keepass_file"
keepass_remote_path="$keepass_remote/$keepass_file"

# import and export commands
database_export="rclone copy $keepass_local_path $rclone_name:$keepass_remote"
database_import="rclone copy $rclone_name:$keepass_remote_path $keepass_local"

# get datetime from string
get_date_from_string() {
    date -d "$1" +"%F %T.%3N"
}

# parse local passwords file modification time
get_local_database_mtime() {
    string=$(stat -c %y "$keepass_local_path" \
        | cut -d ' ' -f 1,2; \
    )
    get_date_from_string "$string"
}

# parse remote passwords file modification time
get_remote_database_mtime() {
    output=$(rclone lsl $rclone_name:$keepass_remote_path 2>/dev/null)
    if [ $? -eq 3 ]; then
        unset output
        return 1
    else
        string=$(printf "%s\n" "$output" \
            | tr -s ' ' \
            | cut -d ' ' -f 3,4; \
        )
        get_date_from_string "$string"
        unset output
        return 0
    fi
}

sync_database() {
    # storing the values
    local_mtime=$(get_local_database_mtime)
    remote_mtime=$(get_remote_database_mtime)

    # modification times
    notify-send "KeePass [Files]" "local:  $local_mtime\nremote: $remote_mtime"

    # if remote file don't exists
    [ -z "$remote_mtime" ] \
        && notify-send "KeePass [Files]" "remote file not found!\nuploading...!" \
        && $database_export \
        && notify-send "KeePass [Database]" "created!" \
        && return 0

    # conversion required for comparison
    local_mtime_sec=$(date -d "$local_mtime" +%s)
    remote_mtime_sec=$(date -d "$remote_mtime" +%s)

    # local file - 10 sec being newer than remote
    if [ $((local_mtime_sec-10)) -gt "$remote_mtime_sec" ]; then
        notify-send "KeePass [Files]" "local file is probably newer than remote!\nuploading...!"
        $database_export
        notify-send "KeePass [Database]" "synchronized!"
        return 0
    # local file +10 sec being older than remote
    elif [ $((local_mtime_sec+10)) -lt "$remote_mtime_sec" ]; then
        notify-send "KeePass [Files]" "local file is probably older than remote!\ndownloading...!"
        $database_import
        notify-send "KeePass [Database]" "synchronized!"
        return 0
    else
        notify-send "KeePass [Database]" "allready synchronized!"
        return 0
    fi
}

# check internet connection
if ping -c1 -W1 -q 1.1.1.1 >/dev/null 2>&1; then
    sync_database
else
    notify-send "KeePass [Failure]" "internet connection not available!"
    exit 1
fi
