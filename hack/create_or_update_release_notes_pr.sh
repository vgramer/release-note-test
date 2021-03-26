#!/usr/bin/env bash

# TODO DOC

set -o errexit
set -o nounset
set -o pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
source "${ROOT}/hack/util.sh"

util::require-hub

release_note_branch='update-release-notes'
base_branch='master'
pr_number="$(hub pr list -h update-release-notes --format '%I')"

if [[ -z "${pr_number}" ]]; then
  pr_exist=false
  echo "release notes pr does note already exist"
  git checkout -b "${release_note_branch}"
else
  pr_exist=true
  echo "release notes pr already exist (#pr_number)"
  hub pr checkout "${pr_number}"
  git reset --hard "${base_branch}"
fi

echo "=================================================================================================================="
echo  "generating next release notes"
echo "=================================================================================================================="

"${ROOT}"/hack/generate_release_notes.sh

echo "=================================================================================================================="
echo  "release notes successfully generated"
echo  "merging next release notes with changelog"
echo "=================================================================================================================="

echo -e "\n" >> next-release-notes.md
cat next-release-notes.md CHANGELOG.md > tmp_changelog.md
mv tmp_changelog.md CHANGELOG.md


if ! git config  user.name > /dev/null 2>&1; then
    echo "git user.name is not set. Setting git config user.name and user.email"
    git config user.name 'GitHub Action'
    git config user.email 'action@github.com'
fi


git add CHANGELOG.md
git commit -m "update changelog with new version"
echo "push new changelog on branch ${release_note_branch}"
git push origin "${release_note_branch}" -f

if [[ "${pr_exist}" == false ]]; then
echo "create release note PR"
  hub pull-request --base master --head "${release_note_branch}" --file "${ROOT}/.github/release-notes-pr-description.md"
fi
