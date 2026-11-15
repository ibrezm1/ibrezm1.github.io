#!/bin/bash
set -eo pipefail

# Script to fetch all GitHub repositories with GitHub Pages enabled 
# (or containing "io" in the name) and export them to a JSON file.

# Verify required dependencies
command -v gh >/dev/null 2>&1 || { echo "Error: 'gh' CLI is required but not installed." >&2; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "Error: 'jq' is required but not installed." >&2; exit 1; }

echo "Fetching repositories..."

page=1
tmp_file="tmp_projects.json"
temp_merge="tmp_merge.json"
echo "[]" > "$tmp_file"

cleanup() {
  rm -f "$temp_merge"
  if [ -f "$tmp_file" ]; then
    rm -f "$tmp_file"
  fi
}
trap cleanup EXIT

while true; do
  echo "Fetching page $page..."
  if ! repos=$(gh api "/user/repos?per_page=100&page=$page"); then
    echo "Error: Failed to fetch repositories from GitHub API on page $page." >&2
    exit 1
  fi

  # Verify repos is a valid JSON array
  if ! echo "$repos" | jq -e 'type == "array"' >/dev/null 2>&1; then
    echo "Error: API returned unexpected response: $repos" >&2
    exit 1
  fi

  len=$(echo "$repos" | jq length)
  if [ "$len" -eq 0 ]; then
    break
  fi

  # Extract relevant fields for repos with pages or "io" in name
  page_repos=$(echo "$repos" | jq '[.[] | select(.has_pages or (.name | contains("io"))) | {name: .name, url: ("https://" + .owner.login + ".github.io/" + .name), github_url: .html_url, description: (.description // ""), pushed_at: .pushed_at}]')

  # Merge with existing array safely
  jq -s '.[0] + .[1]' "$tmp_file" <(echo "$page_repos") > "$temp_merge"
  mv "$temp_merge" "$tmp_file"

  page=$((page+1))
done

# Validate output before overwriting projects.json
if jq -e 'type == "array" and length > 0' "$tmp_file" >/dev/null 2>&1; then
  mv "$tmp_file" projects.json
  echo "Successfully exported $(jq length projects.json) projects to projects.json!"
elif jq -e 'type == "array" and length == 0' "$tmp_file" >/dev/null 2>&1; then
  echo "Warning: No matching repositories found. Preserving existing projects.json."
else
  echo "Error: Generated JSON is invalid. Existing projects.json was not modified." >&2
  exit 1
fi
