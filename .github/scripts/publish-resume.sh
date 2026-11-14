#!/usr/bin/env bash
# Publish only validated resume.pdf, using release IDs for all draft operations.
# Intended to run after the build job on main with GH_TOKEN (contents: write).
set -Eeuo pipefail

[[ -n "$GH_TOKEN" && -n "$GITHUB_REPOSITORY" && -n "$GITHUB_SHA" ]] ||
  { echo "::error::Missing GitHub publication environment"; exit 1; }

repo="$GITHUB_REPOSITORY"
stable_asset="resume.rafael.camacho.latest.pdf"
timezone="America/Mexico_City"

fail() { echo "::error::$*" >&2; exit 1; }

main_is_current() {
  local head
  head=$(gh api "repos/$repo/branches/main" --jq '.commit.sha')
  [[ "$head" == "$GITHUB_SHA" ]]
}

# All queries against drafts use /releases/{id}, never /releases/tags/{tag}.
release_rows() {
  gh api --paginate "repos/$repo/releases?per_page=100" \
    --jq '.[] | [.id, .tag_name, .target_commitish, (.draft | tostring)] | @tsv'
}

tag_taken() {
  local tag="$1"
  git show-ref --tags --verify --quiet "refs/tags/$tag" ||
    gh api --paginate "repos/$repo/releases?per_page=100" \
      --jq '.[].tag_name' | grep -Fxq "$tag"
}

asset_info() {
  local release_id="$1" asset_name="$2"
  gh api "repos/$repo/releases/$release_id" \
    --jq ".assets[] | select(.name == \"$asset_name\") | [.id, .size, (.digest // \"\")] | @tsv"
}

verify_asset() {
  local release_id="$1" asset_name="$2" expected_size="$3" expected_hash="$4"
  local info id size digest
  info=$(asset_info "$release_id" "$asset_name")
  [[ -n "$info" ]] || fail "Asset $asset_name missing from release $release_id"
  IFS=$'\t' read -r id size digest <<< "$info"
  [[ "$size" == "$expected_size" ]] ||
    fail "Size mismatch for $asset_name (got $size, expected $expected_size)"
  if [[ -n "$expected_hash" && -n "$digest" ]]; then
    [[ "$digest" == "sha256:$expected_hash" ]] ||
      fail "SHA-256 mismatch for $asset_name"
  fi
}

upload_if_missing() {
  local release_id="$1" file="$2" asset_name
  asset_name=$(basename "$file")
  if [[ -z "$(asset_info "$release_id" "$asset_name")" ]]; then
    # GitHub does not resolve unpublished draft tags; use the asset upload
    # endpoint with the release ID, sending the PDF's raw bytes.
    curl --fail-with-body --silent --show-error --retry 2 \
      -H "Authorization: Bearer $GH_TOKEN" \
      -H "Accept: application/vnd.github+json" \
      -H "Content-Type: application/pdf" \
      --data-binary "@$file" \
      "https://uploads.github.com/repos/$repo/releases/$release_id/assets?name=$asset_name" \
      >/dev/null
  fi
  verify_asset "$release_id" "$asset_name" "$expected_size" "$pdf_sha256"
}

# One-time recovery for the known orphan produced by the original vN workflow.
# Preserve its exact source SHA and binary; do not reconstruct an old PDF.
recover_legacy_draft() {
  local id=445107846
  local original_sha="e918a0bf2d2d5c30a5025131b52be5c5ec6c4e66"
  local current_tag target draft created stamp old_id version_name
  if ! gh api "repos/$repo/releases/$id" >/dev/null 2>&1; then
    echo "Legacy draft $id not present; no migration needed."
    return
  fi

  target=$(gh api "repos/$repo/releases/$id" --jq '.target_commitish')
  [[ "$target" == "$original_sha" ]] ||
    fail "Legacy release $id points to unexpected source $target"

  draft=$(gh api "repos/$repo/releases/$id" --jq '.draft')
  if [[ "$draft" == "false" ]]; then
    echo "Original release $id has already been recovered."
    return
  fi

  current_tag=$(gh api "repos/$repo/releases/$id" --jq '.tag_name')
  created=$(gh api "repos/$repo/releases/$id" --jq '.created_at')
  stamp=$(TZ="$timezone" date -d "$created" +%Y%m%d%H%M)
  [[ "$stamp" =~ ^[0-9]{12}$ ]] || fail "Invalid original release timestamp"
  [[ "$current_tag" == "v1" || "$current_tag" == "$stamp" ]] ||
    fail "Unexpected legacy draft tag $current_tag"

  if [[ "$current_tag" == "v1" ]]; then
    if tag_taken "$stamp"; then
      fail "Cannot migrate v1: timestamp $stamp is already in use"
    fi
    gh api -X PATCH "repos/$repo/releases/$id" \
      -f tag_name="$stamp" -f name="$stamp" --jq '.id' >/dev/null
  fi

  # This preexisting asset is already uploaded. Rename rather than download
  # or re-encode, so its contents and source association remain unchanged.
  version_name="resume.rafael.camacho.$stamp.pdf"
  if [[ -z "$(asset_info "$id" "$version_name")" ]]; then
    old_id=$(gh api "repos/$repo/releases/$id" \
      --jq ".assets[] | select(.name == \"$stable_asset\") | .id")
    [[ -n "$old_id" ]] || fail "Legacy draft $id has no recoverable PDF"
    gh api -X PATCH "repos/$repo/releases/assets/$old_id" \
      -f name="$version_name" --jq '.name' >/dev/null
  fi

  local original_size
  original_size=$(gh api "repos/$repo/releases/$id" \
    --jq ".assets[] | select(.name == \"$version_name\") | .size")
  [[ "$original_size" =~ ^[1-9][0-9]*$ ]] || fail "Legacy PDF is missing or empty"
  gh api -X PATCH "repos/$repo/releases/$id" \
    -F draft=false -f make_latest=false --jq '.tag_name' >/dev/null
  local published_sha
  published_sha=$(gh api "repos/$repo/git/ref/tags/$stamp" --jq '.object.sha')
  [[ "$published_sha" == "$original_sha" ]] ||
    fail "Legacy tag $stamp does not reference its original source commit"
  echo "Recovered original PDF as release $stamp (release ID $id)."
}

test -s resume.pdf || fail "Validated resume.pdf is missing"
expected_size=$(stat -c '%s' resume.pdf)
pdf_sha256=$(sha256sum resume.pdf | cut -d' ' -f1)

if ! main_is_current; then
  echo "::notice::Skipping stale build $GITHUB_SHA; main has moved."
  exit 0
fi

git fetch --tags --force origin
recover_legacy_draft

# Idempotency: one published release per source SHA, even on manual reruns.
release_id=""
tag=""
state=""
while IFS=$'\t' read -r id release_tag source_sha draft; do
  [[ -n "$id" ]] || continue
  if [[ "$source_sha" == "$GITHUB_SHA" ]]; then
    [[ -z "$release_id" ]] ||
      fail "Multiple releases exist for source SHA $GITHUB_SHA"
    release_id="$id"
    tag="$release_tag"
    state="$draft"
  fi
done <<< "$(release_rows)"

if [[ -n "$release_id" && "$state" == "false" ]]; then
  echo "Source commit $GITHUB_SHA is already published as $tag."
  exit 0
fi

if [[ -z "$release_id" ]]; then
  # Wait for the next minute in the rare case of two releases in one minute.
  # Never overwrite an existing timestamp tag or fabricate a future date.
  tag=""
  for attempt in $(seq 1 14); do
    candidate=$(TZ="$timezone" date +%Y%m%d%H%M)
    if ! tag_taken "$candidate"; then
      tag="$candidate"
      break
    fi
    sleep 5
  done
  [[ -n "$tag" ]] || fail "No free minute timestamp after 70 seconds"

  notes=$(printf 'Source commit: %s\nPDF SHA-256: %s\nTimezone: %s\n' \
    "$GITHUB_SHA" "$pdf_sha256" "$timezone")
  release_id=$(gh api -X POST "repos/$repo/releases" \
    -f tag_name="$tag" -f name="$tag" -f target_commitish="$GITHUB_SHA" \
    -f body="$notes" -F draft=true -F prerelease=false \
    --jq '.id')
  [[ "$release_id" =~ ^[0-9]+$ ]] || fail "Failed to create a draft release"
  echo "Created release draft $tag (ID $release_id)."
else
  [[ "$tag" =~ ^[0-9]{12}$ && "$state" == "true" ]] ||
    fail "Existing draft $release_id has unexpected tag or state"
  echo "Resuming release draft $tag (ID $release_id)."
fi

# Same validated PDF, two download names: a stable Latest URL and a
# timestamped historical file. Never clobber an existing uploaded asset.
versioned_asset="resume.rafael.camacho.$tag.pdf"
cp resume.pdf "$stable_asset"
cp resume.pdf "$versioned_asset"
upload_if_missing "$release_id" "$stable_asset"
upload_if_missing "$release_id" "$versioned_asset"

if ! main_is_current; then
  echo "::notice::Leaving $tag as draft because main moved."
  exit 0
fi

gh api -X PATCH "repos/$repo/releases/$release_id" \
  -F draft=false -f make_latest=true --jq '.tag_name' >/dev/null

published_sha=$(gh api "repos/$repo/git/ref/tags/$tag" --jq '.object.sha')
[[ "$published_sha" == "$GITHUB_SHA" ]] ||
  fail "Release tag $tag points to $published_sha, not $GITHUB_SHA"

latest_id=$(gh api "repos/$repo/releases/latest" --jq '.id')
[[ "$latest_id" == "$release_id" ]] ||
  fail "GitHub Latest points to release $latest_id, not $release_id"

echo "Published $tag from $GITHUB_SHA, SHA-256 $pdf_sha256."
