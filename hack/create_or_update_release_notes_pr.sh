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
  echo "release notes pr does note already exist"
  git checkout -b "${release_note_branch}"
else
  echo "release notes pr already exist (#pr_number)"
  hub pr checkout "${pr_number}"
  git reset --hard master
fi

echo "=================================================================================================================="
echo "=================================================================================================================="
echo  "generating next release notes"

${ROOT}/hack/generate_release_notes.sh

echo "=================================================================================================================="
echo "=================================================================================================================="
echo  "release notes succesfully generated"
echo  "merging next release notes with changelog"


echo -e "\n" >> next-release-notes.md
cat next-release-notes.md CHANGELOG.md > tmp_changelog.md
mv tmp_changelog.md CHANGELOG.md

git add CHANGELOG.md
git commit -m "update changelog with new version"

echo "create or update PR"
hub pull-request --file release-notes-pr-description.md --force

