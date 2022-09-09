#!/usr/bin/env bash
#
# Basic functions to work with a flat JSON file stored in GitHub Gist (https://gist.github.com/)
#
# * Create a Gist with file or files to work with
#   (Script cannot create a new file, it only manipulate JSON data in existing file)
# * File content must be a valid JSON, e.g. "{}" for empty document
# * Set the GIST_ID variable in this script
# * Generate a PAT with "gist, read:org, repo" permissions
#   (read:org and repo are required by GH CLI, https://cli.github.com/manual/gh_auth_login)
# * Set PAT value to GH_TOKEN environment variable

readonly GIST_ID="c98730315eea08c61750d008fa3c3ba7"

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

# Make it working in GitBash
# See https://github.com/git-for-windows/git/issues/577#issuecomment-166118846
[[ "$(uname)" =~ (^[[:alpha:]]+) ]]
[[ "${BASH_REMATCH[1],,}" = mingw* ]] && export MSYS_NO_PATHCONV=1

readonly GH_MIME="Accept: application/vnd.github+json"
readonly GH_AUTH="Authorization: Bearer ${GH_TOKEN}"

#######################################
# Get value of JSON key
# Arguments:
#   Gist file
#   JSON key
# Returns:
#   Key value or "null" if key doesn't exist
#######################################
__get() {
    file="${1}"; shift
    key="${1}"; shift
    content_json=$(_get_content "${file}")
    echo "${content_json}" | jq -r --arg k "${key}" '.[$k]'
}

#######################################
# Update JSON key with a new value
# Create a new key when doesn't exist
# Set value to "null" to delete/remove key from a JSON
# Arguments:
#   Gist file
#   JSON key
#   JSON key value
#######################################
__update() {
    file="${1}"; shift
    key="${1}"; shift
    value="${1}"; shift

    content_current=$(_get_content "${file}")

    if [[ "${value}" == "null" ]]; then
        content_updated=$(jq -r --arg k "${key}" 'del(.[$k])' <<< "${content_current}")
    else
        exists=$(jq --arg k "${key}" 'has("$k")' <<< "${content_current}")
        if [[ "${exists}" == "true" ]]; then
            content_updated=$(jq --arg k "${key}" --arg v "${value}" '.[$k] |= $v' <<< "${content_current}")
        else
            content_updated=$(jq --arg k "${key}" --arg v "${value}" '. += { ($k): $v }' <<< "${content_current}")
        fi
    fi

    _put_content "${file}" "${content_updated}"
}

#######################################
# Delete key from a JSON
# Key value set to "null" deletes the key from JSON
# Arguments:
#   Gist file
#   JSON key
#######################################
__delete() {
    file="${1}"; shift
    key="${1}"; shift
    __update "${file}" "${key}" "null"
}

_get_content() {
    file="${1}"; shift
    content_json=$(gh api --header "${GH_MIME}" "/gists/${GIST_ID}" | jq -r '.files["'${file}'"].content')
    echo "${content_json}"
}

_put_content() {
    file="${1}"; shift
    content="${1}"; shift
    content_json=$(_escape_json "${content}")

    data='{"files": {"'${file}'": {"content": "'"${content_json}"'"}}}'

    curl --silent --output /dev/null --request PATCH --header "${GH_MIME}" --header "${GH_AUTH}" \
        "https://api.github.com/gists/${GIST_ID}" \
        --data-binary "${data}"
}

_escape_json() {
    json="${1}"; shift
    jq '.' <<< "${json}" | sed 's/"/\\\"/g' | sed -z 's/\n/\\n/g'
}

_main() {
    action="${1:-}"; shift

    if [[ "$(type -t "__${action}")" != "function" ]]; then
        echo "Unknown action: ${action}"
        exit 3
    fi

    "__${action}" "${@}"
}

[[ "${BASH_VERSINFO[0]}" -lt 4 ]] && echo "Requires Bash >= 4" && exit 44
[[ "${BASH_SOURCE[0]}" == "${0}" ]] && _main "${@}"
