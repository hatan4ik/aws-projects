#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
TEMP_TFVARS=""

cleanup() {
  if [[ -n "${TEMP_TFVARS}" && -f "${TEMP_TFVARS}" ]]; then
    rm -f "${TEMP_TFVARS}"
  fi
}
trap cleanup EXIT

TF_VARS_FILE="${TF_VARS_FILE:-}"
DEFAULT_SSM_PARAMETER="/ami-pipeline/${DEPLOYMENT_GROUP_NAME:-default}/tfvars"
TF_VARS_SSM_PARAMETER="${TF_VARS_SSM_PARAMETER:-${DEFAULT_SSM_PARAMETER}}"

resolve_tfvars_file() {
  if [[ -n "${TF_VARS_FILE}" && -f "${TF_VARS_FILE}" ]]; then
    echo "${TF_VARS_FILE}"
    return 0
  fi

  if command -v aws >/dev/null 2>&1; then
    echo "Downloading tfvars from SSM parameter ${TF_VARS_SSM_PARAMETER}..."
    TEMP_TFVARS="$(mktemp)"
    if aws ssm get-parameter \
      --with-decryption \
      --name "${TF_VARS_SSM_PARAMETER}" \
      --query 'Parameter.Value' \
      --output text \
      > "${TEMP_TFVARS}"; then
      echo "${TEMP_TFVARS}"
      return 0
    fi
    echo "Failed to read SSM parameter ${TF_VARS_SSM_PARAMETER}" >&2
  else
    echo "aws CLI is not available on this host." >&2
  fi
  return 1
}

TFVARS_PATH="$(resolve_tfvars_file)"

if [[ -z "${TFVARS_PATH}" || ! -f "${TFVARS_PATH}" ]]; then
  echo "A tfvars file is required. Provide TF_VARS_FILE or create SSM parameter ${TF_VARS_SSM_PARAMETER}." >&2
  exit 1
fi

echo "Using tfvars file at ${TFVARS_PATH}"

cd "${ROOT_DIR}"

./scripts/deploy.sh -f "${TFVARS_PATH}"
