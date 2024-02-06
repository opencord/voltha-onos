#!/bin/bash
# Copyright 2017-2024 Open Networking Foundation (ONF) and the ONF Contributors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

##-------------------##
##---]  GLOBALS  [---##
##-------------------##
# set -euo pipefail
umask 022

## -----------------------------------------------------------------------
## Intent: Display an error mesage then exit with shell exit status
## -----------------------------------------------------------------------
function error()
{
    echo "${BASH_SOURCE[0]} ERROR: $*"
    exit 1
}

## -----------------------------------------------------------------------
## Intent: Verify required environment variables are set
## -----------------------------------------------------------------------
## TODO: Covert into command line args
## -----------------------------------------------------------------------
# shellcheck disable=SC2120
function init()
{
    declare -a vars=()
    vars+=('APP_INSTALL_ROOT')
    vars+=('APPS_ROOT')
    vars+=('DOWNLOAD_ROOT')
    vars+=('KARAF_M2')

    local var
    for var in "${vars[@]}";
    do
        [[ ! -v "$var" ]] && { error "EnvVar ${var}= is required"; }
    done

    cat <<EOM

** -----------------------------------------------------------------------
** Running: $0 $@
** -----------------------------------------------------------------------
** $(declare -p APP_INSTALL_ROOT)
** $(declare -p APPS_ROOT)
** $(declare -p DOWNLOAD_ROOT)
** -----------------------------------------------------------------------
EOM

    return
}

## -----------------------------------------------------------------------
## Intent: Gather artifact *.oar files to unpack
## -----------------------------------------------------------------------
## GIVEN
##   ref   An indirect array variable to return values through.
##   dir   Directory to glob *.oar files from
## -----------------------------------------------------------------------
function get_oar_files()
{
    local -n ref=$1 ; shift
    local dir="$1"  ; shift

    readarray -t oars < <(find "$dir" -name '*.oar' -type f -print)
    [[ ${#oars[@]} -eq 0 ]] && { error "No \*.oar files detected in $dir"; }

    # shellcheck disable=SC2034
    ref=("${oars[@]}")
    return
}

##----------------##
##---]  MAIN  [---##
##----------------##

declare arg
while [[ $# -gt 0 ]]; do
    arg="$1"; shift
    case "$arg" in
        '--debug') declare -g -i debug=1 ;;
        *) echo "[SKIP] Unknown argument [$arg]" ;;
    esac
done

init

declare -a oars
get_oar_files oars "$DOWNLOAD_ROOT"

for oar in "${oars[@]}"; do

    app_xml="$APP_INSTALL_ROOT/app.xml"
    oar_basename="${oar##*/}"    # bash builtin

    cat <<EOF

** -----------------------------------------------------------------------
** Artifact: ${oar##*/}
** -----------------------------------------------------------------------
EOF

    echo "Installing application '${oar##*/}'"
    rm -rf "$APP_INSTALL_ROOT"
    mkdir -p "$APP_INSTALL_ROOT"

    ## pushd()/popd(): cd $here && cd $root w/error checking
    pushd "$APP_INSTALL_ROOT" >/dev/null \
        || { error "pushd failed: $APP_INSTALL_ROOT"; }

    [[ -v debug ]] && { echo "** Installing: $oar"; }

    set -x
    rsync --checksum "$oar" "$APP_INSTALL_ROOT/."
    unzip -oq -d . "$APP_INSTALL_ROOT/${oar_basename}"
    set +x

    # ------------------------------------------------------------
    # [IN]  <app name="org.opencord.kafka" origin="ONF" version="2.13.2"
    # [OUT] declare -a names=([0]="org.opencord.kafka")
    # ------------------------------------------------------------
    readarray -t names < <(grep 'name=' "$app_xml" \
			                   | sed 's/<app name="//g;s/".*//g')

    [[ ${#names[@]} -gt 0 ]] \
        || { error "Detected invalid name gathering"; }

    printf '** %s\n' "$(declare -p names)"
    name="${names[0]}"
    apps_name="$APPS_ROOT/$name"

    mkdir -p "$apps_name"
    rsync -v --checksum "$app_xml" "${apps_name}/app.xml"

    touch "${apps_name}/active" # what is this used for (?)

    declare app_png="$APP_INSTALL_ROOT/app.png"
    [ -f "$app_png" ] && { rsync -v --checksum "$app_png" "${apps_name}/."; }
    cp "${APP_INSTALL_ROOT}/${oar_basename}" "${apps_name}/${name}.oar"

    rsync -rv --checksum "${APP_INSTALL_ROOT}/m2/." "$KARAF_M2/."
    rm -rf "$APP_INSTALL_ROOT"

    popd >/dev/null || { error "popd failed: $APP_INSTALL_ROOT"; }

done

# [EOF]
