#!/usr/bin/env sh

#######################
# Project: fpp
# Author:  ConzZah
# LM:      2025.11.18 
#######################

firefox=""; path2profile="$(pwd)/fpp"
### check if firefox is even installed & exit if it shouldn't be
command -v firefox >/dev/null && firefox="$(command -v firefox)"
[ -z "$firefox" ] && echo "--> ERROR: FIREFOX COULD NOT BE FOUND" && exit 1

### if $path2profile couldn't be found, and is equal to the default,
### check if the 7z archive is present, if not, download & extract it, and create .fr
[ ! -d "$path2profile" ] && [ "$path2profile" = "$(pwd)/fpp" ] && {
[ ! -f "fpp.7z" ] && command -v curl >/dev/null && echo '--> DOWNLOADING fpp.7z' && \
curl -#LO 'https://github.com/ConzZah/fpp/raw/refs/heads/main/fpp.7z'
7z x -y "fpp.7z" && touch "$path2profile/.fr"
}

### check again, so we don't try to load something that's not there
[ ! -d "$path2profile" ] && echo "--> ERROR: COULDN'T FIND PATH TO PROFILE"

### delete addonStartup.json.lz4, to make addon/extension paths fix themselves
rm -f "$path2profile/addonStartup.json.lz4" >/dev/null

### if $1 is '-fr', create firstrun flag
[ "$1" = '-fr' ] && touch "$path2profile/.fr"

### if .fr (firstrun flag) does exist, prepare & perform first run 
[ -f ".fr"  ] || [ -f "$path2profile/.fr" ] && {
echo '--> PREPARING FIRST RUN, PLS WAIT..'
rm -f "$path2profile/.fr" ".fr" >/dev/null
rm -f "$path2profile/sessionstore.jsonlz4" >/dev/null
rm -rf "$path2profile/sessionstore-backups" >/dev/null
}

### if .fr doesn't exist, launch normally 
[ ! -f ".fr"  ] || [ ! -f "$path2profile/.fr" ] && \
echo "--> LAUNCHING FIREFOX WITH PROFILE @ $path2profile"
$firefox --allow-downgrade --profile "$path2profile" >/dev/null 2>&1 &
