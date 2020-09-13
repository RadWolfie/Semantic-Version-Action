# Semantic Version Action

**NOTICE: It does not create local tag for you. You can create local tag from your workflow with `version_current` output variable.**

The following formats will be base on push, tag, and pull request.
```
v#.#.<patch> (default)
v#.#.# (Only exceptional for annotated tag event trigger.)
v#.#.<patch>+<#######> (forked repository)
v#.#.<patch>-pr<#>+<#######> (pull request)
```
 * General event trigger will perform `v#.#.<patch>` depending on initial version values or from previous tag.
    * Patch is base on total commits from beginning of the branch excluding any commits came from merged commit.
    * However, if operating from forked repository. Versioning will be treat as default method with addition of build hash.
 * Tag event will follow exactly semantic version, you will need to use annotated tag in order to get this event trigger.
 * Pull request will generate base on previous tag or initial version plus with format of `-pr<#>+<#######>`. Single digit number, `#`, will base on pull request number whilst `#######` is a build hash from merged commit.

## Usage
### Pre-requisites
Create a workflow `.yml` file in your `.github/workflows` directory. An [example workflow](#example-workflow---create-a-semantic-version) is available below. For more information, reference the GitHub Help Documentation for [Creating a workflow file](https://help.github.com/en/articles/configuring-a-workflow#creating-a-workflow-file).

### Inputs

- `repository`: Default repository to focus on official release versioning.
- `version_major_init`: Major initial version value.
- `version_minor_init`: Minor initial version value.
- `fetch_tags`: `true` to fetch tags information, `false` to assumed tags had been already fetched. Default: `false`

### Outputs

- `version_previous`: Previous tag version or otherwise will point to beginning of the branch.
- `version_current`: Current tag version which will also have generated semantic version depending on events occur.

### Example workflow - create a semantic version
On every `push` to a tag matching the pattern `v*`, any branches, pull request, or even on schedule for every five minutes will trigger the workflow.

```yaml
on:
  push:
    # Sequence of patterns matched against refs/tags
    tags:
      - 'v*' # Push events to matching v*, i.e. v1.0, v20.15.10
    # Any branches or specific branch
    branches:
  pull_request:
  schedule:
    - cron: '*/5 * * * *'

name: Generate Semantic Version

jobs:
  build:
    name: Generate Semantic Version
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
        with:
          fetch-depth: 0
      - uses: RadWolfie/Semantic-Version-Action@main
        id: semver-output
        with:
          repository: ${{ env.repo_default }}
          version_major_init: 0
          version_minor_init: 1
      - name: Output Semantic Version
        run: |
          echo previous version: ${{ steps.semver-output.outputs.version_previous }}
          echo current version: ${{ steps.semver-output.outputs.version_current }}
```
