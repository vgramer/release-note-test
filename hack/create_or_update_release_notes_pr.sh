#!/usr/bin/env bash

# TODO DOC

set -o errexit
set -o nounset
set -o pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
source "${ROOT}/hack/util.sh"

util::require-hub

release_note_branch='update-release-notes'
pr_number="$(hub pr list -h update-release-notes --format '%I')"

if [[ -z "${pr_number}" ]]; then
  git checkout -b "${release_note_branch}"
else
  hub pr checkout "${pr_number}"
  git reset --hard master
fi


${ROOT}/hack/generate_release_notes.sh

echo -e "\n" >> next-release-notes.md
cat next-release-notes.md CHANGELOG.md > tmp_changelog.md
mv tmp_changelog CHANGELOG.md

git add CHANGELOG.md
git commit -m "update changelog with new version"

hub pull-request --file release-notes-pr-description.md --force



