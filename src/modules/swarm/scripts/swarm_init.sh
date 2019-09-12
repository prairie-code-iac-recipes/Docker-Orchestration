#!/bin/bash

set -eou pipefail

execute_command() {
  SSH_KEY_FILE=$1
  USER=$2
  HOST=$3
  COMMAND=$4

  local RESPONSE
  # RESPONSE=$(ssh -i ${SSH_KEY_FILE} ${USER}@${HOST} -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o LogLevel=QUIET "(${COMMAND} 2>&1 | grep -o 'SWMTKN.*' 2>&1)")
  RESPONSE=$(ssh -i ${SSH_KEY_FILE} ${USER}@${HOST} -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "(${COMMAND} 2>&1 | grep -o 'SWMTKN.*' 2>&1)")
  echo ${RESPONSE}
}

# -----------------------------------------------------------------------------
# Parse and Validate Inputs
# -----------------------------------------------------------------------------
eval "$(jq -r '@sh "WORKING_DIR=\(.working_dir) USER=\(.user) HOST=\(.ssh_host) DOCKER_HOST=\(.docker_host) PRIVATE_KEY=\(.private_key)"')"

if [ -z ${WORKING_DIR} ]; then
  >&2 echo "working_dir (${WORKING_DIR}) must be specified and it must point to a valid directory."
  >&2 ls "${WORKING_DIR}"
  exit 2
elif [ ! -d "${WORKING_DIR}" ]; then
  >&2 echo "working_dir (${WORKING_DIR}) must point to a valid directory."
  exit 3
elif [ -z ${USER} ]; then
  >&2 echo "user must be specified."
  exit 4
elif [ -z ${HOST} ]; then
  >&2 echo "host must be specified."
  exit 5
elif [ -z ${PRIVATE_KEY} ]; then
  >&2 echo "private_key must contain a base64 encoded ssh private key."
  exit 6
fi

PRIVATE_KEY_FILE="${WORKING_DIR}/$(openssl rand -base64 6 | sed 's/\///').key"
if [ $(uname) == 'Darwin' ]; then
  echo ${PRIVATE_KEY} | base64 --decode > ${PRIVATE_KEY_FILE}
else
  echo ${PRIVATE_KEY} | base64 -d > ${PRIVATE_KEY_FILE}
fi
chmod 400 ${PRIVATE_KEY_FILE}

WORKER=$(execute_command ${PRIVATE_KEY_FILE} ${USER} ${HOST} 'docker swarm join-token worker')
if [[ ! "$WORKER" =~ ^SWMTKN.*$ ]]; then
  WORKER=$(execute_command ${PRIVATE_KEY_FILE} ${USER} ${HOST} "docker swarm init --advertise-addr ${DOCKER_HOST}")
fi
MANAGER=$(execute_command ${PRIVATE_KEY_FILE} ${USER} ${HOST} 'docker swarm join-token manager')

if [[ "$WORKER" =~ ^SWMTKN.*$ ]] && [[ "$MANAGER" =~ ^SWMTKN.*$ ]]; then
  echo "{ \"worker\": \"${WORKER}\", \"manager\": \"${MANAGER}\" }"
  exit 0
else
  >&2 echo "Unable to retrieve one or more join tokens (${WORKER}, ${MANAGER})"
  exit 7
fi
