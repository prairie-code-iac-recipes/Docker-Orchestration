#!/bin/sh

set -e pipefail

# -----------------------------------------------------------------------------
# Validate Inputs
# -----------------------------------------------------------------------------
ERROR=0
if [ -z "${GITLAB_TOKEN}" ]; then
  echo "The variable GITLAB_TOKEN must be provided!"
  ERROR=$((${ERROR}+1))
fi

if [ -z "${GITLAB_URL}" ]; then
  echo "The variable GITLAB_URL must be provided!"
  ERROR=$((${ERROR}+1))
fi

if [ -z "${KEY}" ]; then
  echo "A variable KEY must be provided!"
  ERROR=$((${ERROR}+1))
fi

if [ -z "${VALUE}" ]; then
  echo "A variable VALUE must be provided!"
  ERROR=$((${ERROR}+1))
fi

if [ -z "${VERSION}" ]; then
  echo "The variable VERSION must be provided!"
  ERROR=$((${ERROR}+1))
fi

RESOURCE=
if [ ! -z "${GROUP_ID}" ]; then
  RESOURCE="groups/${GROUP_ID}/variables"
elif [ ! -z "${PROJECT_ID}" ]; then
  RESOURCE="projects/${PROJECT_ID}/variables"
else
  echo "Either the variable GROUP_ID or the variable PROJECT_ID must be provided!"
  ERROR=$((${ERROR}+1))
fi

if (( ERROR != 0 )); then
  exit ${ERROR}
fi

echo "${GITLAB_URL}/${RESOURCE}"

# -----------------------------------------------------------------------------
# Save Variable to Gitlab CI/CD Variable
# -----------------------------------------------------------------------------
DATA="\"key\": \"${KEY}_${VERSION}\""
DATA="$DATA, \"value\": \"${VALUE}\""
DATA="$DATA, \"variable_type\": \"env_var\""

STATUS=$(curl -X POST -o /dev/null -w '%{http_code}' --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" --header "Content-Type: application/json" --data "{ $DATA }" "${GITLAB_URL}/${RESOURCE}")

if [ $STATUS -ne 201 ]; then
  echo "Unable to Save Versioned Variable: $STATUS"
  exit 1
else
  echo "Successfully Saved Versioned Variable"
fi
