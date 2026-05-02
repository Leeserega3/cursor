#!/usr/bin/env bash
# BSL Language Server runner.
#
# Downloads the BSL LS executable jar (cached in .bsl-ls/) and runs it in
# analyze mode on the configuration sources.
#
# Usage:
#   scripts/bsl-ls.sh                       # analyze 1c-config/src, console reporter
#   scripts/bsl-ls.sh --reporter json       # produce reports/bsl-json.json
#   scripts/bsl-ls.sh --reporter sarif      # produce reports/bsl-ls.sarif
#   BSL_LS_VERSION=0.29.0 scripts/bsl-ls.sh # pin a specific version

set -euo pipefail

VERSION="${BSL_LS_VERSION:-0.29.0}"
SRC_DIR="${BSL_LS_SRC_DIR:-1c-config/src}"
OUT_DIR="${BSL_LS_OUT_DIR:-reports}"
CACHE_DIR="${BSL_LS_CACHE_DIR:-.bsl-ls}"
CONFIG_FILE="${BSL_LS_CONFIG:-.bsl-language-server.json}"
JAR="${CACHE_DIR}/bsl-language-server-${VERSION}-exec.jar"
URL="https://github.com/1c-syntax/bsl-language-server/releases/download/v${VERSION}/bsl-language-server-${VERSION}-exec.jar"

mkdir -p "${CACHE_DIR}" "${OUT_DIR}"

if [[ ! -f "${JAR}" ]]; then
  echo "[bsl-ls] downloading ${URL}" >&2
  if command -v curl >/dev/null 2>&1; then
    curl -fL --retry 3 --retry-delay 2 -o "${JAR}.part" "${URL}"
  else
    wget -O "${JAR}.part" "${URL}"
  fi
  mv "${JAR}.part" "${JAR}"
fi

if ! command -v java >/dev/null 2>&1; then
  echo "[bsl-ls] java is required (BSL LS ${VERSION} needs JDK 17+)" >&2
  exit 1
fi

if [[ ! -d "${SRC_DIR}" ]] || [[ -z "$(ls -A "${SRC_DIR}" 2>/dev/null | grep -v '^\.gitkeep$' || true)" ]]; then
  echo "[bsl-ls] no sources found in '${SRC_DIR}' — put your 1С configuration dump there." >&2
  exit 0
fi

CONFIG_ARGS=()
if [[ -f "${CONFIG_FILE}" ]]; then
  CONFIG_ARGS=(-c "${CONFIG_FILE}")
fi

echo "[bsl-ls] analyzing ${SRC_DIR} (version ${VERSION})" >&2
exec java -Xmx2g -jar "${JAR}" \
  "${CONFIG_ARGS[@]}" \
  analyze \
  --srcDir "${SRC_DIR}" \
  --workspaceDir "$(pwd)" \
  --outputDir "${OUT_DIR}" \
  "$@"
