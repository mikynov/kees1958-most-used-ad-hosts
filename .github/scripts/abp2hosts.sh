#!/usr/bin/env bash

readonly TRACE="${TRACE:-}"
[[ -n "${TRACE}" ]] && set -o xtrace
set -o errexit
set -o errtrace
set -o nounset
set -o pipefail
set -o noclobber
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC2034
readonly SCRIPT_DIR

WHITELIST=(
    "discord.com"
    "godaddy.com"
    "linkedin.com"
)

_convert() {
    # shellcheck disable=SC2016
    regex='^(\|\|)([^*]*\.[a-zA-Z]{2,})(\^)?(\$third-party)$'

    declare -a output
    i=0
    while IFS= read -r line; do
        if [[ $line =~ $regex ]]; then
            match="${BASH_REMATCH[2]}"
            if [[ " ${WHITELIST[*]} " =~ ${match} ]]; then
                echo "Skipping ${match} (whitelist)" >&2
            else
                printf -v domain "0.0.0.0 %s" "${match}"
                output+=("${domain}")
                i=$((i+1))
            fi
        fi
    done

    cat <<HEADER
# Title: ${GITHUB_REPOSITORY}/EU_US_MV2_most_common_ad+tracking_networks.hosts
#
# This hosts file is generated from ${1/\/raw\//\/blob\/}
#
# Date: $(date --utc --iso-8601=seconds)
# Number of converted hosts: ${i}
#
# The latest version of this file: https://raw.githubusercontent.com/${GITHUB_REPOSITORY}/${GITHUB_REF_NAME}/EU_US_MV2_most_common_ad%2Btracking_networks.hosts
#
# ===============================================================
HEADER

    echo "${output[*]}"
}

_main() {
    file="${1}" && shift
    curl --silent --location "${file}" | _convert "${file}"
}

[[ "${BASH_VERSINFO[0]}" -lt 4 ]] && echo "Requires Bash >= 4" && exit 44
[[ "${BASH_SOURCE[0]}" == "${0}" ]] && _main "${@}"
