#!/bin/bash

semver_sh=${GITHUB_ACTION_PATH}/scripts/tool/semver/semver

if [ "${INPUT_FETCH_TAGS}" == "true" ]
then
  git fetch --tags
fi

if [ "${IS_PR}" == "true" ]
then
  echo "Pull Request detected."
  target_branch=origin/${GITHUB_BASE_REF}
  echo "PR total commits: $(git rev-list --first-parent --count origin/${GITHUB_HEAD_REF})"
else
  target_branch=${GITHUB_REF}
fi
#echo "target_branch=${target_branch}" >> $GITHUB_OUTPUT
echo "::debug::target_branch: ${target_branch}"

total_commits=$(git rev-list --first-parent --count ${target_branch})
version_major=${INPUT_VERSION_MAJOR_INIT}
version_minor=${INPUT_VERSION_MINOR_INIT}
version_patch=${total_commits}
echo "::debug::target total commits: ${total_commits}"

short_commit_sha=$(git rev-parse --short HEAD)
#echo "short_commit_sha=${short_commit_sha}" >> $GITHUB_OUTPUT
echo "::debug::commit sha: ${short_commit_sha}"

# Using tagger date in GitHub Actions may not work correctly, it does work fine locally.
tag_total=$(git tag | wc -l)
echo "::debug::total of tags found: ${tag_total}"

if [ "${IS_TAG}" == "true" ]
then
  if [ ${tag_total} -gt 1 ]
  then
    version_previous=$(git rev-list --tags --skip=1 --max-count=1)
    version_previous=$(git describe --tags --abbrev=0 ${version_previous})
  else
    version_previous=${target_branch}~$(($total_commits-1))
  fi
else
  version_previous=$(git rev-list --tags --max-count=1)
  echo "::debug::verify if has existing tag: ${version_previous}"
  if [ -z "${version_previous}" ]
  then
    version_previous=${target_branch}~$(($total_commits-1))
    tag_init=true
  else
    version_previous=$(git describe --tags --abbrev=0 ${version_previous})
  fi
fi

tag_hash=$(git rev-parse $version_previous)
tag_offset=$(git rev-list --count ${version_previous}..HEAD)
echo "tag_offset=${tag_offset}" >> $GITHUB_OUTPUT

#generate build version
if [ "${IS_TAG}" == "true" ]
then
  version_current=${GITHUB_REF#refs/tags/}
else
  # if tag was initialized, then get current major/minor versions.
  if [ -z "${tag_init}" ]
  then
    version_major=$(${semver_sh} get major ${version_previous})
    if [ -z "${version_major}" ]
    then
      exit 1
    fi
    version_minor=$(${semver_sh} get minor ${version_previous})
  fi

  if [ "${IS_PR}" == "true" ]
  then
    version_current=v${version_major}.${version_minor}.${version_patch}-pr${PR_NUM}+${short_commit_sha}
  elif [ "${INPUT_REPOSITORY}" == "${GITHUB_REPOSITORY}" ]
  then
    version_current=v${version_major}.${version_minor}.${version_patch}
  else
    version_current=v${version_major}.${version_minor}.${version_patch}+${short_commit_sha}
  fi
fi

echo "version_previous=${version_previous}" >> $GITHUB_OUTPUT
echo version_previous: ${version_previous}
echo "version_current=${version_current}" >> $GITHUB_OUTPUT
echo version_current: ${version_current}
