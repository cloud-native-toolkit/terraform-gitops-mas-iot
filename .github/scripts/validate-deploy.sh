#!/usr/bin/env bash

SCRIPT_DIR=$(cd $(dirname "$0"); pwd -P)

source "${SCRIPT_DIR}/validation-functions.sh"

GIT_REPO=$(cat git_repo)
GIT_TOKEN=$(cat git_token)

BIN_DIR=$(cat .bin_dir)

export PATH="${BIN_DIR}:${PATH}"

if ! command -v oc 1> /dev/null 2> /dev/null; then
  echo "oc cli not found" >&2
  exit 1
fi

if ! command -v kubectl 1> /dev/null 2> /dev/null; then
  echo "kubectl cli not found" >&2
  exit 1
fi

export KUBECONFIG=$(cat .kubeconfig)
NAMESPACE=$(cat .namespace)
COMPONENT_NAME=$(jq -r '.name // "my-module"' gitops-output.json)
BRANCH=$(jq -r '.branch // "main"' gitops-output.json)
SERVER_NAME=$(jq -r '.server_name // "default"' gitops-output.json)
LAYER=$(jq -r '.layer_dir // "2-services"' gitops-output.json)
TYPE=$(jq -r '.type // "base"' gitops-output.json)

APPNAME=$(jq -r '.appname // "manage"' gitops-output.json)
WSNAME=$(jq -r '.ws_name // "demo"' gitops-output.json)
INSTNAME=$(jq -r '.inst_name // "masdemo"' gitops-output.json)

mkdir -p .testrepo

git clone https://${GIT_TOKEN}@${GIT_REPO} .testrepo

cd .testrepo || exit 1

find . -name "*"

set -e

validate_gitops_content "${NAMESPACE}" "${LAYER}" "${SERVER_NAME}" "${TYPE}" "${COMPONENT_NAME}" "values.yaml"

check_k8s_namespace "${NAMESPACE}"

## testing for operator separtely here because it only needs 30min timer, the other deployments need much longer
count=0
until kubectl get deployment ibm-mas-iot-operator -n ${NAMESPACE} || [[ $count -eq 30 ]]; do
  echo "Waiting for deployment/ibm-mas-iot-operator in ${NAMESPACE}"
  count=$((count + 1))
  sleep 60
done

if [[ $count -eq 30 ]]; then
  echo "Timed out waiting for deployment/ibm-mas-iot-operator in ${NAMESPACE}"
  kubectl get all -n "${NAMESPACE}"
  exit 1
fi


check_k8s_resource "${NAMESPACE}" "deployment" "webui-api-dashboard"

check_k8s_resource "${NAMESPACE}" "deployment" "provision-operator"

check_k8s_resource "${NAMESPACE}" "deployment" "datapower-operator"

check_k8s_resource "${NAMESPACE}" "deployment" "datapower-datapower"


cd ..
rm -rf .testrepo
