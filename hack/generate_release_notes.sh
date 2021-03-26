#!/usr/bin/env bash

# TODO DOC
# GITHUB_REPOSITORY	The owner and repository name. For example, octocat/Hello-World

set -o errexit
set -o nounset
set -o pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
source "${ROOT}/hack/util.sh"

function check_environment() {
  util::require-hub
  util::command_exists "release-notes" || util::fatal 'release-notes not found in path. Please install it before running script. `go get `'

  set +o nounset
  if [[ -z "${GITHUB_TOKEN}" ]]; then
    util::fatal "'GITHUB_TOKEN' environment variable is not defined or empty"
  fi

  if [[ -z "${GITHUB_REPOSITORY}" ]]; then
    util::fatal "'GITHUB_REPOSITORY' environment variable is not defined or empty"
  fi
  set -o nounset

  [[ ${GITHUB_REPOSITORY} =~ ^[^/]+/[^/]+$ ]] || util::fatal "could not extract organization and repository from GITHUB_REPOSITORY env var. GITHUB_REPOSITORY='${GITHUB_REPOSITORY}'"
  org=$(echo "${GITHUB_REPOSITORY}" | cut -d '/' -f 1)
  repo=$(echo "${GITHUB_REPOSITORY}" | cut -d '/' -f 2)
}

check_environment

echo "org=${org} repo=${repo}"

# format '%pI %T%n' -> "publish_date_ISO_8601 tag\n". eg:2 021-03-24T20:10:00Z v3.0.0
last_release_tag="$(hub release -f '%pI %T%n' | sort -nr | head -1 | cut -d ' ' -f 2)"

if [[ -z "${last_release_tag}" ]]; then
  echo "no release found on repository. fallback to first commit"
  start_sha="$(git rev-list --max-parents=0 HEAD)"
  echo "first commit sha is '${start_sha}'"
else
  echo "last release found. it's tag '${last_release_tag}'"
  start_sha=$(git rev-parse "${last_release_tag}")
  echo "tag '${last_release_tag}' point on commit '${start_sha}'"
fi

end_sha=$(git rev-parse HEAD)

# generate release notes:
#  * for pr merged in master by any users (--required-author='').
#  * without go dependencies report (--dependencies=false)
release-notes --start-sha "${start_sha}" \
  --end-sha "${end_sha}" \
  --required-author='' \
  --branch master \
  --org "${org}" \
  --repo "${repo}" \
  --go-template=go-template:"${ROOT}/.github/release-notes.tmpl" \
  --output "${ROOT}/next-release-notes.md" \
  --dependencies=false
