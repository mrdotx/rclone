#!/bin/sh

# path:       /home/klassiker/.local/share/repos/rclone/sync_keepass.sh
# author:     klassiker [mrdotx]
# github:     https://github.com/mrdotx/rclone
# date:       2020-11-24T13:52:10+0100

rclone_name="dropbox"
keepass_file="klassiker.kdbx"
keepass_local="$HOME/.local/share/cloud/dropbox/.keepass/"
keepass_remote="/.keepass"

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

# parse local file modification time
get_local_database_mtime() {
    string=$(stat -c %y "$keepass_local_path" \
        | cut -d ' ' -f 1,2; \
    )
    get_date_from_string "$string"
}

# parse remote file modification time
get_remote_database_mtime() {
    output=$(rclone lsl $rclone_name:$keepass_remote_path 2>/dev/null)
        string=$(printf "%s\n" "$output" \
            | tr -s ' ' \
            | cut -d ' ' -f 3,4; \
        )
        get_date_from_string "$string"
}

sync_database() {
    # storing the values for comparison
    local_mtime=$(get_local_database_mtime)
    local_mtime_sec=$(date -d "$local_mtime" +%s)
    remote_mtime=$(get_remote_database_mtime)
    remote_mtime_sec=$(date -d "$remote_mtime" +%s)

    message_times="local file time:  $local_mtime\nremote file time: $remote_mtime"

    # if remote file don't exists
    if [ -z "$remote_mtime" ]; then
        notify-send \
            "KeePass [Files] - uploading..." \
            "remote file not found\n$message_times"
        $database_export
        notify-send \
            "KeePass [Database] - created!"
    # local file -10 sec being newer than remote
    elif [ $((local_mtime_sec-10)) -gt "$remote_mtime_sec" ]; then
        notify-send \
            "KeePass [Files] - uploading..." \
            "local file is newer than remote\n$message_times"
        $database_export
        notify-send \
            "KeePass [Database] - synchronized!"
    # local file +10 sec being older than remote
    elif [ $((local_mtime_sec+10)) -lt "$remote_mtime_sec" ]; then
        notify-send \
            "KeePass [Files] - downloading..." \
            "local file is older then remote\n$message_times"
        $database_import
        notify-send \
            "KeePass [Database] - synchronized!"
    else
        notify-send \
            "KeePass [Database] - up to date!"
    fi
}

# check internet connection
if ping -c1 -W1 -q 1.1.1.1 >/dev/null 2>&1; then
    sync_database
else
    notify-send \
        "KeePass [Failure] - internet connection not available!"
    exit 1
fi
