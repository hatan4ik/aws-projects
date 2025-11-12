#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE' >&2
Usage: scripts/deploy.sh [-f /path/to/vars.tfvars]

Options:
  -f    Path to the tfvars file that should be used for plan/apply.
        You can also set the TF_VARS_FILE environment variable.
  -h    Show this help message.
USAGE
}

TF_VARS_FILE="${TF_VARS_FILE:-}"

while getopts ":f:h" opt; do
  case "${opt}" in
    f)
      TF_VARS_FILE="${OPTARG}"
      ;;
    h)
      usage
      exit 0
      ;;
    \?)
      usage
      exit 1
      ;;
  esac
done

shift $((OPTIND - 1))

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
INFRA_DIR="${REPO_ROOT}/infrastructure"

if [[ -z "${TF_VARS_FILE}" ]]; then
  TF_VARS_FILE="${INFRA_DIR}/terraform.tfvars"
fi

if [[ "${TF_VARS_FILE}" != /* ]]; then
  CANDIDATE="${REPO_ROOT}/${TF_VARS_FILE}"
  if [[ -f "${CANDIDATE}" ]]; then
    TF_VARS_FILE="${CANDIDATE}"
  fi
fi

if [[ ! -f "${TF_VARS_FILE}" ]]; then
  echo "Unable to locate tfvars file at ${TF_VARS_FILE}" >&2
  exit 1
fi

TF_VARS_ABS="$(cd "$(dirname "${TF_VARS_FILE}")" && pwd)/$(basename "${TF_VARS_FILE}")"

echo "Building Lambda packages..."
"${REPO_ROOT}/scripts/build_lambdas.sh"

cd "${INFRA_DIR}"

echo "Initializing Terraform..."
terraform init -input=false

echo "Planning Terraform deployment with ${TF_VARS_ABS}..."
terraform plan -input=false -var-file="${TF_VARS_ABS}" -out=tfplan

echo "Applying Terraform deployment..."
terraform apply -input=false tfplan

echo "Deployment complete!"
