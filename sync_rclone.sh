#!/bin/sh

# path:   /home/klassiker/.local/share/repos/rclone/sync_rclone.sh
# author: klassiker [mrdotx]
# github: https://github.com/mrdotx/rclone
# date:   2021-01-15T13:53:52+0100

# color variables
green=$(tput setaf 2)
blue=$(tput setaf 12)
reset=$(tput sgr0)

script=$(basename "$0")
help="$script [-h/--help] -- script to copy/sync from/to cloud with rclone
  Usage:
    $script [-check/-copy/-sync_to/-sync_from]

  Setting:
      -check     = check
      -copy      = copy
      -sync_to   = sync to destination
      -sync_from = sync from destination

  Example:
    $script -check
    $script -copy
    $script -sync_to
    $script -sync_from"

rclone_directory="$HOME/.local/share/cloud"
rclone_config="
web.de;       $rclone_directory/webde/;       webde:/;       $rclone_directory/webde/.filter
GMX;          $rclone_directory/gmx/;         gmx:/;         $rclone_directory/gmx/.filter
Google Drive; $rclone_directory/googledrive/; googledrive:/; $rclone_directory/googledrive/.filter
OneDrive;     $rclone_directory/onedrive/;    onedrive:/;    $rclone_directory/onedrive/.filter
Dropbox;      $rclone_directory/dropbox/;     dropbox:/;     $rclone_directory/dropbox/.filter
"

rclone_vars() {
    title=$(printf "%s" "$1" \
        | cut -d ";" -f1 \
        | tr -d ' ' \
    )
    source_directory=$(printf "%s" "$1" \
        | cut -d ";" -f2 \
        | tr -d ' ' \
    )
    destination_directory=$(printf "%s" "$1" \
        | cut -d ";" -f3 \
        | tr -d ' ' \
    )
    filter_file=$(printf "%s" "$1" \
        | cut -d ";" -f4 \
        | tr -d ' ' \
    )
}

rclone_check() {
    printf "[%s%s%s] <-> %s%s%s\n" "$green" "$1" "$reset" "$blue" "$2" "$reset"
    rclone check -l -P "$2" "$3" --filter-from="$4"
    printf "\n"
}

rclone_copy() {
    printf "[%s%s%s] <- %s%s%s\n" "$green" "$1" "$reset" "$blue" "$2" "$reset"
    rclone copy -l -P "$2" "$3" --filter-from="$4"
    printf "[%s%s%s] -> %s%s%s\n" "$green" "$1" "$reset" "$blue" "$2" "$reset"
    rclone copy -l -P "$3" "$2" --filter-from="$4"
    printf "\n"
}

rclone_sync_to() {
    printf "[%s%s%s] <- %s%s%s\n" "$green" "$1" "$reset" "$blue" "$2" "$reset"
    rclone sync -l -P "$2" "$3" --filter-from="$4"
    printf "\n"
}

rclone_sync_from() {
    printf "[%s%s%s] -> %s%s%s\n" "$green" "$1" "$reset" "$blue" "$2" "$reset"
    rclone sync -l -P "$3" "$2" --filter-from="$4"
    printf "\n"
}

rclone_execute() {
    printf "%s\n" "$rclone_config" | {
        while IFS= read -r line; do
            [ -n "$line" ] \
                && rclone_vars "$line" \
                && $1 "$title" "$source_directory" "$destination_directory" "$filter_file"
        done
    }
}

case "$1" in
    -check)
        rclone_execute "rclone_check"
        ;;
    -copy)
        rclone_execute "rclone_copy"
        ;;
    -sync_to)
        rclone_execute "rclone_sync_to"
        ;;
    -sync_from)
        rclone_execute "rclone_sync_from"
        ;;
    *)
        printf "%s\n" "$help"
        exit 1
        ;;
esac
