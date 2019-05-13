# VOLTHA ONOS Development Build Environment

Docker build environment capable of producing a version of onos and needed apps that can run with voltha.  Typically the onos restful api would be used to include apps after onos is started.  This provides a build environment that includes current released and enabled oar files or optionally can import locally built oar files.


## Build

By default the current set of onos apps is imported from a maven repository as read from `dependencies.xml`.  
```sh
make build
```


## Including locally built oar files

If you wish to include your own onos apps then export the `LOCAL_ONOSAPPS` environment variable to have locally built oar files copied from `local_imports/oar` into the docker build environment rather than pulling from maven.  Any oar files in this directory will be included and set to start on onos startup.  

Note!  its assumed that the standard apps (olt-app, sadis, aaa, and dhcpl2relay) build environment is one up directory from this build environment.  Modify `get-local-oars.sh` if this is not the case:

```sh
export LOCAL_ONOSAPPS=true
make build
```

## Including custom config

The voltha-onos build also includes a mechanism to build in a default onos `network-config.json` file.   You can simply edit `network-cfg.json` before building the docker image.  Or if using docker-compose or k8s volume mount over the built in file within the container `/root/onos/config/network-cfg.json` with your own.

For example, in a docker-compose file:

```sh
  onos:
    image: "${DOCKER_REGISTRY}${DOCKER_REPOSITORY}voltha-onos:${DOCKER_TAG}"
    ports:
    - "8101:8101" # ssh
    - "6653:6653" # OF
    - "8181:8181" # UI
    environment:
      ONOS_APPS: 'drivers,openflow-base'
    volumes:
    - "/var/run/docker.sock:/tmp/docker.sock"
    - "./network-cfg.json:/root/onos/config/network-cfg.json"
    networks:
    - default
    restart: unless-stopped
```
