#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LAMBDA_DIR="${REPO_ROOT}/lambda"
PACKAGE_DIR="${LAMBDA_DIR}/packages"

mkdir -p "${PACKAGE_DIR}"

shopt -s nullglob
LAMBDA_SOURCES=("${LAMBDA_DIR}"/*.py)
if [[ ${#LAMBDA_SOURCES[@]} -eq 0 ]]; then
  echo "No Lambda source files found under ${LAMBDA_DIR}" >&2
  exit 1
fi

for source_path in "${LAMBDA_SOURCES[@]}"; do
  function_name="$(basename "${source_path}" .py)"
  echo "Packaging ${function_name}..."
  (
    cd "${LAMBDA_DIR}"
    zip -q "packages/${function_name}.zip" "${function_name}.py"
  )
done
shopt -u nullglob

echo "Lambda packages built successfully in ${PACKAGE_DIR}"
