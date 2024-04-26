#!/bin/sh

# path:   /home/klassiker/.local/share/repos/rclone/sync_rclone.sh
# author: klassiker [mrdotx]
# github: https://github.com/mrdotx/rclone
# date:   2024-04-25T09:59:48+0200

# color variables
green="\033[32m"
blue="\033[94m"
reset="\033[0m"

script=$(basename "$0")
help="$script [-h/--help] -- script to copy/sync from/to cloud with rclone
  Usage:
    $script [-check/-copy/-sync_to/-sync_from]

  Setting:
      -check     = check differences between local and cloud
      -copy      = copy from/to cloud
      -sync_to   = sync to cloud
      -sync_from = sync from cloud

  Example:
    $script -check
    $script -copy
    $script -sync_to
    $script -sync_from"

rclone_dir="$HOME/Cloud"
rclone_config="
      web.de; $rclone_dir/webde/;       webde:/;        8,0G
         GMX; $rclone_dir/gmx/;         gmx:/;          8,0G
Google Drive; $rclone_dir/googledrive/; googledrive:/; 17,0G
    OneDrive; $rclone_dir/onedrive/;    onedrive:/;     5,0G
     Dropbox; $rclone_dir/dropbox/;     dropbox:/;      3,25G
"

get_config_value() {
    printf "%s" "$1" \
        | cut -d ";" -f"$2" \
        | tr -d ' '
}

clone() {
    printf "%b%s%b $2 %b%s%b\n" "$green" "$4" "$reset" "$blue" "$5" "$reset"

    ! [ -d "$6" ] \
        && printf "folder \"%s\" not found...\n\n" "$6" \
        && return

    rclone "$1" -l -P "$4" "$5" --filter-from="$6.filter" \
        && printf "%s/%s\n" \
            "$(du -sh "$6" | cut -d'	' -f1)" \
            "$7" > "$6.usage"

    printf "\n"
}

execute() {
    printf "%s\n" "$rclone_config" \
        | while IFS= read -r line; do
            [ -n "$line" ] \
                && clone "$1" "$3" \
                    "$(get_config_value "$line" "1")" \
                    "$(get_config_value "$line" "$2")" \
                    "$(get_config_value "$line" "$4")" \
                    "$(get_config_value "$line" "2")" \
                    "$(get_config_value "$line" "4")"
        done
}

case "$1" in
    -check)
        execute "check" "2" "<->" "3"
        ;;
    -copy)
        execute "copy" "2" "->" "3"
        execute "copy" "3" "->" "2"
        ;;
    -sync_to)
        execute "sync" "2" "->" "3"
        ;;
    -sync_from)
        execute "sync" "3" "->" "2"
        ;;
    *)
        printf "%s\n" "$help"
        exit 1
        ;;
esac
