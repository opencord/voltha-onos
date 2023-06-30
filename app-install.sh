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
declare -g HERE; HERE="$(pwd)"

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
function init()
{
    [[ ! -v APP_INSTALL_ROOT ]] && error "Var APP_INSTALL_ROOT= is required"
    [[ ! -v DOWNLOAD_ROOT ]]    && error "Var DOWNLOAD_ROOT= is required"
    return
}

##----------------##
##---]  MAIN  [---##
##----------------##

init

readarray -t OARS < <(find "$DOWNLOAD_ROOT" -name '*.oar')
for oar in "${OARS[@]}"; do

    app_xml="$APP_INSTALL_ROOT/app.xml"
    oar_basename="${oar##*/}"    # bash builtin

    cd "$HERE" || error "cd $HERE failed"
    echo "Installing application '$oar'"
    rm -rf "$APP_INSTALL_ROOT"
    mkdir -p "$APP_INSTALL_ROOT"
    cd "$APP_INSTALL_ROOT"  || error "cd $APP_INSTALL_ROOT failed"
    cp -v "$oar" "$APP_INSTALL_ROOT"
    unzip -oq -d . "$APP_INSTALL_ROOT/${oar_basename}"

    readarray -t names < <(grep "name=" "$app_xml" \
			       | sed 's/<app name="//g;s/".*//g')
    [[ ${#names[@]} -gt 0 ]] || error "Detected invalid name gathering"
    name="${names[1]}"
    apps_name="$APPS_ROOT/$name"

    mkdir -p "$apps_name"
    cp "$app_xml" "${apps_name}/app.xml"
    touch "${apps_name}/active"
    [ -f "$APP_INSTALL_ROOT/app.png" ] \
	&& cp "$APP_INSTALL_ROOT/app.png" "${apps_name}/app.png"
    cp "${APP_INSTALL_ROOT}/${oar_basename}" "${apps_name}/${name}.oar"
    cp -rf "$APP_INSTALL_ROOT/m2/"* "$KARAF_M2"
    rm -rf "$APP_INSTALL_ROOT"
done

# [EOF]
