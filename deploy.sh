#!/bin/bash
SCRIPT_DIR="$( dirname -- "$( readlink -f -- "$0" )" )"
BASE_DIR=$( realpath "${SCRIPT_DIR}" )

# needs jq and curl
PATH_REQS="jq curl"
for _PT in $PATH_REQS; do
    which "${_PT}" >/dev/null 2>&1
    if [ "$?" -ne "0" ]; then
        >&2 echo "E: [${_PT}] not found. Make sure [${_PT}] is available and in path."
        exit 1
    fi
done

NODE_ADDR="$1"
ACTION="$2"

if [ -z "${NODE_ADDR}" ]; then
    >&2 echo "E: Missing node address."
    echo "Usage: $0 <node_address> <up|down>"
    exit 1
fi

hostname -I | grep "${NODE_ADDR}" > /dev/null

if [ "$?" -ne "0" ]; then # check if IP address found.
    >&2 echo "E: IP address [${NODE_ADDR}] not found [ $(hostname -I 2>/dev/null) ]."
    exit 1
fi

ping -q -c1 "${NODE_ADDR}" >/dev/null
if [ "$?" -ne "0" ]; then
    >&2 echo "E: IP address [${NODE_ADDR}] not connected."
    exit 1
fi

# check latest etcd release from github
LATEST_VER=$(curl https://api.github.com/repos/etcd-io/etcd/releases/latest 2>/dev/null | jq -r '.name')
IMAGE_REGISTRY="gcr.io/etcd-development/etcd"

# if etcd-browser image is unspecified, we use default.
if [ -z "${ETCD_BROWSER_IMAGE}" ]; then
    ETCD_BROWSER_IMAGE="etcd-browser:latest"
fi

# check if etcd-browser image is already built. if no, advise user to build it.
docker image ls --format "{{.Repository}}:{{.Tag}}" "${ETCD_BROWSER_IMAGE}" 2>/dev/null | grep "${ETCD_BROWSER_IMAGE}" >/dev/null 2>&1
if [ "$?" -ne "0" ]; then
    echo "W: Cannot find local image [${ETCD_BROWSER_IMAGE}]."
    docker manifest inspect "${ETCD_BROWSER_IMAGE}" >/dev/null 2>&1
    if [ "$?" -ne "0" ]; then
        >&2 echo "E: Cannot find local/remote image [${ETCD_BROWSER_IMAGE}]".
        >&2 echo "E: Try building image before running deploy.sh by running:"
        >&2 echo "E: [ docker build . -t ${ETCD_BROWSER_IMAGE} ]"
        exit 1
    fi
fi

# export variables.
export IMAGE_REGISTRY LATEST_VER NODE_ADDR ETCD_BROWSER_IMAGE

# compose up/down!
if [ "$2" == "down" ]; then
    docker compose down
else
    docker compose up -d
fi
