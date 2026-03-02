#!/usr/bin/env sh

#===============================================
# Project: fpp/firefox.sh
# Author:  ConzZah
# Last Modification: 3/2/26 01:47 AM
#===============================================

# shellcheck disable=SC2009 # REASON: pgrep is not POSIX
# shellcheck disable=SC2012 # REASON: THERE ARE NO NON-ALPHANUMERIC FILENAMES WE'D NEED TO WORRY ABOUT 

banner () { printf '%s\n' '
===============================
 FPP v1.6 /// ConzZah /// 2026
===============================
';}

help () { 
banner
printf '%s\n' 'OPTIONS:

-m        USE MOST RECENT PROFILE

-p        SPECIFY PATH TO PROFILE

-fr       CREATE FIRSTRUN FLAG

-kill     PUT THE FOX TO REST

-help     SHOW THIS HELP

-RESET    RESET FPP

'; exit ;}

init () {
deps="curl grep cat cut sed tr 7z"
foxes="firefox-esr firefox librewolf"
firefox_path="$HOME/.mozilla/firefox"
librewolf_path="$HOME/.config/librewolf/librewolf"
firefox_path_flatpak="$HOME/.var/app/org.mozilla.firefox/config/mozilla/firefox"
librewolf_path_flatpak="$HOME/.var/app/io.gitlab.librewolf-community/.librewolf"
pathnotfound="--> ERROR: COULDN'T FIND PATH TO PROFILE"; custom_path=""
firefox=""; flatpak=""; path2profile="$(pwd)/fpp"; url=""

## check if firefox is even installed & exit if it shouldn't be
[ -z "$firefox" ] && {
for fox in $foxes; do
command -v "$fox" >/dev/null && firefox="$fox" && break; done

## set $firefox_path
[ "$firefox" = "librewolf" ] && firefox_path="$librewolf_path"
}

## if we have no match yet, try the flatpak versions
[ -z "$firefox" ] && command -v flatpak >/dev/null && {
foxes='org.mozilla.firefox io.gitlab.librewolf-community'
for fox in $foxes; do
flatpak list| grep -q "$fox" && \
firefox="$fox" && flatpak="1" && break; done

## set $firefox_path
[ "$firefox" = "org.mozilla.firefox" ] && firefox_path="$firefox_path_flatpak"
[ "$firefox" = "io.gitlab.librewolf-community" ] && firefox_path="$librewolf_path_flatpak"
path2profile="$firefox_path/fpp"
firefox="flatpak run $firefox"
}

## if $firefox is still empty, we're fucked
[ -z "$firefox" ] && printf '%s\n' "--> ERROR: FIREFOX APPEARS TO BE MISSING." && exit 1

## check for common deps
for dep in $deps; do 
! command -v "$dep" >/dev/null && \
printf '%s\n' "--> ERROR: DEPENDENCY: $dep MISSING" && \
exit 1
done


### PROCESS ARGS ###
while [ "$#" -gt "0" ]; do
case $1 in

m|M|'-m'|'-M')
## find the path to the most recently used firefox profile
[ ! -d "$firefox_path" ] && printf '%s\n' "$pathnotfound" && exit 1
path2profile="$(ls -t "$firefox_path"/*/prefs.js| head -n1| sed 's#prefs.js##g')"; shift
custom_path="1"
;;

p|P|'-p'|'-P')
## if the user wants to specify a path to a profile, check if it exists
shift; path2profile="$1"

## if $path2profile is also valid when putting $(pwd) in front, overwrite it to gain the full path
[ -d "$path2profile" ] && [ -d "$(pwd)/$path2profile" ] && path2profile="$(pwd)/$path2profile"

[ -d "$path2profile" ] && shift
## if $path2profile doesn't seem to exist, then we tried
[ ! -d "$path2profile" ] && printf '%s\n' "$pathnotfound" && exit 1
## refuse for flatpak versions, if they don't contain $firefox_path 
[ -n "$flatpak" ] && printf '%s' "$path2profile"| grep -vq "$firefox_path" && \
printf '%s\n' '--> ERROR: FLATPAKS ARE RESTRICTED TO THEIR RESPECTIVE DIRS' && exit 1
custom_path="1"
;;

k|K|'-k'|'-K'|'-kill')
## kill firefox if the user asks for it
[ ! -f ".pid" ] && printf '%s\n' '--> ERROR: NO .PID FILE FOUND' && exit 1
printf '%s\n' '--> PUTTING THE FOX TO REST'

## flatpak instance
grep -q 'flatpak kill.*' .pid  && { eval "$(cat .pid)"; exit ;}

## normal instance
ps -aux| grep -v grep| grep -qo "$(cat .pid)" && {
kill -15 "$(cat .pid)"; [ -f ".pid" ] && rm -f .pid; exit ;}
;;

*RESET) 
## RESET completely deletes fpp 
## and re-downloads it.
## you will be prompted.
[ -z "$custom_path" ] && {
printf '\n--> RESET FPP?\n\n[y/N] '
read -r yn
case $yn in
y|Y) rm -vfr "$path2profile" && dl_fpp && \
printf '\n--> FPP HAS BEEN RESET\n\n' && exit 0 || exit 1 ;;
*) printf '\n--> RESET CANCELED.\n\n'; exit 0 ;; 
esac ;}
## refuse to work if $custom_path is nonzero
[ -n "$custom_path" ] && printf '\n--> ERROR: CUSTOM PATH DETECTED, RESET PREVENTED.\n\n' && exit 1
;;

## check if "$1" is reachable and overwrite "$url" if so
## one can open as many urls as they choose
*.*) curl -sI "$1" >/dev/null && url="$url $1"; shift ;; 

## if $1 is '-fr', create firstrun flag
fr|'-fr') touch "$path2profile/.fr"; shift ;;

## help, when needed
h|H|'-h'|'-H'|'help'|*) help ;;
esac
done
}

launch () {
## if $path2profile couldn't be found, 
## and if we don't have a $custom_path set, dl_fpp
[ ! -f "$path2profile/prefs.js" ] && \
[ -z "$custom_path" ] && dl_fpp

## check again, so we don't try to load something that's not there
[ ! -d "$path2profile" ] && { printf '%s\n' "--> ERROR: COULDN'T FIND PATH TO PROFILE"; exit 1 ;}

## delete addonStartup.json.lz4, to make addon/extension paths fix themselves
rm -f "$path2profile/addonStartup.json.lz4" >/dev/null

## if .fr (firstrun flag) does exist, perform first run
[ -f ".fr"  ] || [ -f "$path2profile/.fr" ] && {
printf '%s\n' '--> PERFORMING FIRST RUN, PLS WAIT..'
rm -f "$path2profile/.fr" ".fr" >/dev/null
rm -f "$path2profile/sessionstore.jsonlz4" >/dev/null
rm -rf "$path2profile/sessionstore-backups" >/dev/null
}

### LAUNCH ###
[ -z "$url" ] && url="about:home" ## <-- if $url is empty, go home
fox="$firefox $url --allow-downgrade --profile $path2profile"
$fox >/dev/null 2>&1 &

## get pid, write it to file, and display it
[ -z "$flatpak" ] && { ps -aux| grep ".*$firefox.*$path2profile.*"| grep -v '.*grep.*'| tr -s ' '| cut -d ' ' -f 2| head -n1 > .pid; printf '\n%s\n' "--> PID: $(cat .pid)" ;}
[ -n "$flatpak" ] && printf '%s\n' "$firefox"| sed 's#run#kill#' > .pid
printf '%s\n' "--> VISITING: $url"
printf '%s\n' "--> RUNNING: $($firefox --version)"
printf '%s\n\n' "--> PROFILE: $path2profile"
exit
}

dl_fpp () {
## download & extract fpp.7z, and create .fr
## NOTE: due to flatpaks running in isolated enviroments, 
## we must download fpp to it's respective directory
[ -n "$flatpak" ] && { cd "$firefox_path" || exit 1 ;}
[ ! -f "fpp.7z" ] && printf '\n--> DOWNLOADING fpp.7z\n\n' && \
curl -#LO 'https://github.com/ConzZah/fpp/raw/refs/heads/main/fpp.7z'
[ -f "fpp.7z" ] && printf '\n--> EXTRACTING fpp.7z\n' && \
7z x -y "fpp.7z" >/dev/null && touch "$path2profile/.fr" || exit 1
[ -n "$flatpak" ] && { cd - || exit 1 ;}
return 0
}

init "$@"
launch
