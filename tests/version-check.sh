# Copyright 2021-present Open Networking Foundation

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

# http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

CWD=$( dirname ${BASH_SOURCE[0]} )
NEW_VERSION=$(head -n1 "$CWD/../VERSION")

if [[ "$NEW_VERSION" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]
then
  echo "Version string '$NEW_VERSION' is a SemVer released version!"
  SNAPSHOTS=$(cat "$CWD/../dependencies.xml" | grep "SNAPSHOT" | wc -l)
  if [[ "$SNAPSHOTS" -gt 0 ]]
  then
    echo "ERROR: Referring to -SNAPSHOT apps in a released VERSION"
    exit 1
  fi
fi
