#!/bin/bash

# Script to fetch all GitHub repositories with GitHub Pages enabled 
# (or containing "io" in the name) and export them to a JSON file.

echo "Fetching repositories..."

page=1
tmp_file="tmp_projects.json"
echo "[]" > "$tmp_file"

while true; do
  repos=$(gh api "/user/repos?per_page=100&page=$page")
  len=$(echo "$repos" | jq length)
  
  if [ "$len" -eq 0 ]; then
    break
  fi
  
  # Extract relevant fields for repos with pages or "io" in name
  page_repos=$(echo "$repos" | jq '[.[] | select(.has_pages or (.name | contains("io"))) | {name: .name, url: ("https://" + .owner.login + ".github.io/" + .name), description: (.description // ""), pushed_at: .pushed_at}]')
  
  # Merge with existing array
  jq -s '.[0] + .[1]' "$tmp_file" <(echo "$page_repos") > temp.json && mv temp.json "$tmp_file"
  
  page=$((page+1))
done

mv "$tmp_file" projects.json
echo "Successfully exported projects to projects.json!"
