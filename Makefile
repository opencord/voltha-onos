# -*- makefile -*-
# -----------------------------------------------------------------------
# Copyright 2016-2024 Open Networking Foundation Contributors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# -----------------------------------------------------------------------
# SPDX-FileCopyrightText: 2017-2024 Open Networking Foundation Contributors
# SPDX-License-Identifier: Apache-2.0
# -----------------------------------------------------------------------

.PHONY: help
.DEFAULT_GOAL := help

##--------------------##
##---]  INCLUDES  [---##
##--------------------##
include config.mk
include makefiles/include.mk

# Variables
VERSION                  ?= $(shell cat ./VERSION)

## Docker related
DOCKER_REGISTRY          ?=
DOCKER_REPOSITORY        ?=
DOCKER_BUILD_ARGS        ?=
DOCKER_TAG               ?= ${VERSION}
ONOS_IMAGENAME           := ${DOCKER_REGISTRY}${DOCKER_REPOSITORY}voltha-onos:${DOCKER_TAG}

## Docker labels. Only set ref and commit date if committed
DOCKER_LABEL_VCS_URL     ?= $(shell git remote get-url $(shell git remote))
DOCKER_LABEL_BUILD_DATE  ?= $(shell date -u "+%Y-%m-%dT%H:%M:%SZ")
DOCKER_LABEL_COMMIT_DATE = $(shell git show -s --format=%cd --date=iso-strict HEAD)

ifeq ($(shell git ls-files --others --modified --exclude-standard 2>/dev/null | wc -l | sed -e 's/ //g'),0)
  DOCKER_LABEL_VCS_REF = $(shell git rev-parse HEAD)
else
  DOCKER_LABEL_VCS_REF = $(shell git rev-parse HEAD)+dirty
endif

.PHONY: docker-build

# For each makefile target, add ## <description> on the target line and it will be listed by 'make help'
help :: ## Print help for each Makefile target
	@echo "Usage: $(MAKE) [options] [target] ..."

	@printf '  %-33.33s %s' 'test' \
	  'Run repository based test suites (test=)'
	@printf '  %-33.33s %s' 'test-bats' \
	  'Invoke bats harness shell test suites (wip)'
	@printf '  %-33.33s %s' 'test-release' \
	  'Verify released VERSION does ont contain dev/SNAPSHOT apps'

	@echo
	@grep --no-filename '^[[:alpha:]_-]*:.* ##' $(MAKEFILE_LIST) \
	    | sort \
	    | awk 'BEGIN {FS=":.* ## "}; {printf "  %-25s : %s\n", $$1, $$2};'

## Docker targets

## -----------------------------------------------------------------------
## -----------------------------------------------------------------------
build: docker-build ## alias for "docker-build"

## -----------------------------------------------------------------------
## -----------------------------------------------------------------------
local-onosapps: ## if LOCAL_ONOSAPPS=true runs the get-local-oars.sh
	mkdir -p local_imports/oar
ifdef LOCAL_ONOSAPPS
	$(RM) -r local_imports/oar
	./get-local-oars.sh
endif

## -----------------------------------------------------------------------
## Intent: build docker image
##   use DOCKER_REGISTRY, DOCKER_REPOSITORY and DOCKER_TAG to customize
## -----------------------------------------------------------------------
docker-build: local-onosapps ## build docker image
	docker build $(DOCKER_BUILD_ARGS) \
    -t ${ONOS_IMAGENAME} \
    --build-arg LOCAL_ONOSAPPS=$(LOCAL_ONOSAPPS) \
    --build-arg org_label_schema_version="${VERSION}" \
    --build-arg org_label_schema_vcs_url="${DOCKER_LABEL_VCS_URL}" \
    --build-arg org_label_schema_vcs_ref="${DOCKER_LABEL_VCS_REF}" \
    --build-arg org_label_schema_build_date="${DOCKER_LABEL_BUILD_DATE}" \
    --build-arg org_opencord_vcs_commit_date="${DOCKER_LABEL_COMMIT_DATE}" \
    -f Dockerfile.voltha-onos .

## -----------------------------------------------------------------------
## -----------------------------------------------------------------------
test := $(null)

ifdef TEST-BATS
  test += test-bats
endif

ifdef RELEASE
  test += test-release
endif

test :: $(test) ## verify that if the version is released we're not pointing to SNAPSHOT apps

## -----------------------------------------------------------------------
## Intent: Shell script testing with the bats test harness.
##  Usage: make test TEST-BATS=1
## -----------------------------------------------------------------------
test-bats:
	$(HIDE)$(MAKE) -C test/bats $@

## -----------------------------------------------------------------------
## Intent: Release based testing.
## -----------------------------------------------------------------------
## Usage:
##   make test-release
##   make test RELEASE=1
## -----------------------------------------------------------------------
## Legacy: VERSION validation has been defined as a default repository
##         based test.  The target should be isolated and should only
##         be required durring a release cycle.
## -----------------------------------------------------------------------
test-release :
	bash tests/version-check.sh

## -----------------------------------------------------------------------
## -----------------------------------------------------------------------
docker-push: ## push to docker registy: use DOCKER_REGISTRY, DOCKER_REPOSITORY and DOCKER_TAG to customize
	docker push ${ONOS_IMAGENAME}

## -----------------------------------------------------------------------
## -----------------------------------------------------------------------
clean :: ## clean the build environment
	$(RM) -r local_imports

## -----------------------------------------------------------------------
## -----------------------------------------------------------------------
sterile :: clean

# [EOF]
