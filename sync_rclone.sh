#!/bin/sh

# path:   /home/klassiker/.local/share/repos/rclone/sync_rclone.sh
# author: klassiker [mrdotx]
# url:    https://github.com/mrdotx/rclone
# date:   2025-12-24T06:25:32+0100

# config
rclone_dir="$HOME/Cloud"
rclone_config="
    $rclone_dir/webde/;       webde:/;         8.0G
    $rclone_dir/gmx/;         gmx:/;           8.0G
    $rclone_dir/nextcloud/;   nextcloud:/;   100.0G
    $rclone_dir/dropbox/;     dropbox:/;       3.25G
    $rclone_dir/onedrive/;    onedrive:/;      5.0G
    $rclone_dir/googledrive/; googledrive:/;  17.0G
"

# color variables
reset="\033[0m"
bold="\033[1m"
blue="\033[94m"
cyan="\033[96m"

script=$(basename "$0")
help="$script [-h/--help] -- script to copy/sync from/to cloud with rclone
  Usage:
    $script [--check/--copy/--sync_to/--sync_from]

  Setting:
      --check     = check differences between local and cloud
      --copy      = copy from/to cloud
      --sync_to   = sync to cloud
      --sync_from = sync from cloud

  Example:
    $script --check
    $script --copy
    $script --sync_to
    $script --sync_from

  Config: $rclone_config"

get_config_value() {
    printf "%s" "$1" \
        | cut -d ";" -f"$2" \
        | tr -d ' '
}

clone() {
    printf "%b%b::%b %b%s files%b %b%s%b %b%s%b %b%s%b\n" \
        "$bold" "$blue" "$reset" "$bold" "$1" "$reset" \
        "$cyan" "$3" "$reset" "$bold" "$2" "$reset" "$cyan" "$4" "$reset"

    ! [ -d "$5" ] \
        && printf "folder \"%s\" not found...\n\n" "$5" \
        && return

    rclone "$1" "$3" "$4" --filter-from="$5.filter" \
            --bind 0.0.0.0 --quiet --progress --links \
        && printf "%s/%s\n" \
            "$(du -sh "$5" | cut -f1)" \
            "$6" > "$5.usage"
}

execute() {
    printf "%s\n" "$rclone_config" \
        | while IFS= read -r line; do
            [ -n "$line" ] \
                && clone "$1" "$3" \
                    "$(get_config_value "$line" "$2")" \
                    "$(get_config_value "$line" "$4")" \
                    "$(get_config_value "$line" "1")" \
                    "$(get_config_value "$line" "3")"
        done
}

case "$1" in
    --check)
        execute "check" "1" "<->" "2"
        ;;
    --copy)
        execute "copy" "1" "->" "2"
        execute "copy" "2" "->" "1"
        ;;
    --sync_to)
        execute "sync" "1" "->" "2"
        ;;
    --sync_from)
        execute "sync" "2" "->" "1"
        ;;
    *)
        printf "%s\n" "$help"
        exit 1
        ;;
esac
