#!/bin/bash

# Good practice
set -o errexit   # abort on nonzero exitstatus
set -o nounset   # abort on unbound variable
set -o pipefail  # don't hide errors within pipes

# Personal notes
# Like JS, it's a good idea to remove some warts that have stuck around for compatibility.
# Thus, we have a few good practice adjustments at the start of every script.
#
# The () in function defs is weird because you don't have named arguments. All it does is show
# that a function def is intended here. You can reduncantly use the function keyword, but
# it's not recommended because it's very un-portable and provides no functionality.
#
# () doesn't call functions. 
#
# Declare is automatically local if used inside a function. It depends on the context.


# Helper functions
error () {
  printf "%s\n" "${*}" 1>&2
}

check_support () {
  if ! declare -A assoc; then
    error "associative arrays not supported!"
    exit 1
  fi

  if ! type rsync &> /dev/null; then
    error "Unable to find rsync in PATH."
    exit 2
  fi

  if [ "$EUID" -ne 0 ]; then
    error "Please run this script as root."
    exit 3
  fi
}
check_support

do_rsync () {
  local -r src="${1}"
  local -r dst="${2}"
  printf "Syncing from: %s\n" "${src}"
  rsync -rtv --delete-after --info=progress2 --no-i-r --exclude '.*849C9593-*' "${src}" "${dst}"
  printf '\n'
}

check_path_exists () {
  for path in "${@}"; do
    if [ -d "${path}" ]; then
      printf "  Path validated: %s\n" "${path}"
    else
      error "Invalid path designation: ${path}"
      exit 1
    fi
  done
}


# Globals
# If destination does not exist, it will be created first
# Destinations are all found in backup_path
declare -r -A path_map=(
  ['Justice/james/Desktop']='/mnt/c/Users/birds/Desktop'
  ['Justice/james/Documents']='/mnt/c/Users/birds/Documents'
  ['Justice/james/Downloads']='/mnt/c/Users/birds/Downloads'
  ['Justice/james/Music']='/mnt/c/Users/birds/Music'
  ['Justice/james/OneDrive']='/mnt/c/Users/birds/OneDrive'
  ['Justice/james/Pictures']='/mnt/c/Users/birds/Pictures'
  ['Justice/james/Saved Games']='/mnt/c/Users/birds/Saved Games'
  ['Justice/james/Videos']='/mnt/c/Users/birds/Videos'

  ['Justice/sara/Desktop']='/mnt/c/Users/Sway/Desktop'
  ['Justice/sara/Documents']='/mnt/c/Users/Sway/Documents'
  ['Justice/sara/Downloads']='/mnt/c/Users/Sway/Downloads'
  ['Justice/sara/Music']='/mnt/c/Users/Sway/Music'
  ['Justice/sara/Pictures']='/mnt/c/Users/Sway/Pictures'
  ['Justice/sara/Saved Games']='/mnt/c/Users/Sway/Saved Games'
  ['Justice/sara/Videos']='/mnt/c/Users/Sway/Videos'

  ['Justice/Geneva/Game Installer Cache']='/mnt/d/Game Installer Cache'
  ['Justice/Geneva/ISOs']='/mnt/d/ISOs'
  ['Justice/Geneva/Virtualbox VMs']='/mnt/d/Virtualbox VMs'
  
)

# Body
# Preconditions
printf "Making sure that the C, D, E drives are mounted.\n"
check_path_exists /mnt/{c,d,e}

printf "Enter the path where you mounted the backup drive: \n"
read -r backup_path
check_path_exists "$backup_path"

# sync commands
for dst in "${!path_map[@]}"; do
  src="${path_map[$dst]}"
  real_dst="${backup_path}/${dst}"
  mkdir -p "${real_dst}"
  do_rsync "${src}/" "${backup_path}/${dst}"
done
