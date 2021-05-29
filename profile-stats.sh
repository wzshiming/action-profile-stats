#!/usr/bin/env bash
set -e

function command_exists() {
  local COMMAND="$1"
  type "${COMMAND}" >/dev/null 2>&1
}

function sync() {
  BIN="profile_stats"
  if command_exists "./${BIN}"; then
    "./${BIN}" $@
    return
  elif command_exists "${BIN}"; then
    "${BIN}" $@
    return
  else
    if [[ -z "${TAG}" ]]; then
      TAG="v0.2.1"
    fi

    if [[ -z "${GOOS}" ]]; then
      if [[ "$(uname)" == "Darwin" ]]; then
        GOOS="darwin"
      elif [[ "$(uname -s)" == "Linux" ]]; then
        GOOS="linux"
      elif [[ "$(uname)" =~ "MINGW" ]]; then
        GOOS="windows"
      else
        echo "This system, $(uname), isn't supported"
        exit 1
      fi
    fi

    if [[ -z "${GOARCH}" ]]; then
      ARCH="$(uname -m)"
      case "${ARCH}" in
      x86_64 | amd64)
        GOARCH=amd64
        ;;
      armv8* | aarch64* | arm64)
        GOARCH=arm64
        ;;
      armv*)
        GOARCH=arm
        ;;
      i386 | i486 | i586 | i686)
        GOARCH=386
        ;;
      *)
        echo "This system's architecture, ${ARCH}, isn't supported"
        exit 1
        ;;
      esac
    fi

    NAME="${BIN}_${GOOS}_${GOARCH}"
    if [[ "${GOOS}" == "windows" ]]; then
      NAME="${NAME}.exe"
    fi

    TARGET="https://github.com/wzshiming/${BIN}/releases/download/${TAG}/${NAME}"

    EXEC="${BIN}"
    if [[ "${GOOS}" == "windows" ]]; then
      EXEC="${EXEC}.exe"
    fi

    if command_exists wget; then
      echo "wget ${TARGET}" -c -O "$EXEC"
      wget "${TARGET}" -c -O "$EXEC"
    elif command_exists curl; then
      echo "curl ${TARGET}" -L -o "$EXEC"
      curl "${TARGET}" -L -o "$EXEC"
    else
      echo "No download tool available"
      exit 1
    fi

    chmod +x "./$BIN"
    "./$BIN" $@
  fi
}

for TARGET in ${TARGETS[@]}; do
  echo "Sync ${TARGET}"
  sync "${TARGET}"
done
