#!/bin/bash

# JFrog Artifactory details
ARTIFACTORY_URL="https://louphub.jfrog.io/artifactory"
REPOSITORY_NAME="fossa-generic-local"
# Ensure the ACCESS_TOKEN is set as an environment variable for security
ACCESS_TOKEN="${ACCESS_TOKEN}"

# Function to roll back to a specific version
rollback_to_version() {
  local version_to_rollback=$1
  
  echo "Rolling back to version: $version_to_rollback"

  # Fetch assets for the specified version
  assets_urls=$(curl -s "https://api.github.com/repos/fossas/fossa-cli/releases/tags/v$version_to_rollback" | jq -r '.assets[].browser_download_url')
  
  for url in $assets_urls; do
    local file_name=$(basename "$url")
    
    echo "Downloading $file_name ..."
    curl -L "$url" -o "$file_name"
    
    echo "Uploading $file_name to Artifactory..."
    curl -H "Authorization: Bearer $ACCESS_TOKEN" -T "$file_name" "$ARTIFACTORY_URL/$REPOSITORY_NAME/$file_name"
    
    # Check if the upload was successful
    if [ $? -ne 0 ]; then
        echo "Failed to upload $file_name to Artifactory"
        rm "$file_name"
        exit 1
    fi
    
    echo "Uploaded $file_name to Artifactory."
    rm "$file_name"
  done

  echo "Rollback to $version_to_rollback completed."
}

# Check if version argument is provided
if [ -z "$1" ]; then
    echo "No version specified for the rollback."
    exit 1
fi

# Call rollback function with the specified version
rollback_to_version "$1"


# #!/bin/bash

# # JFrog Artifactory details
# ARTIFACTORY_URL="https://louphub.jfrog.io/artifactory"
# REPOSITORY_NAME="fossa-generic-local"
# ACCESS_TOKEN="${ACCESS_TOKEN}"  # Ensure this is passed as an environment variable

# # Function to fetch all versions from the GitHub RSS feed
# fetch_versions_from_rss() {
#   curl -s "https://github.com/fossas/fossa-cli/releases.atom" |
#   awk 'BEGIN { RS = "<entry>" ; FS = "<title>" } NR>1 { print $2 }' | 
#   sed -n 's/.*v\([0-9.]*\).*/\1/p' |
#   sort -V
# }

# # Function to roll back to a specific version
# rollback_to_version() {
#   local version_to_rollback=$1
  
#   # Construct the download URL based on the version and a known pattern. Adjust this according to actual asset naming conventions.
#   local rollback_url="https://github.com/fossas/fossa-cli/releases/download/v${version_to_rollback}/fossa_${version_to_rollback}_darwin_amd64.zip"
  
#   echo "Rolling back to version: $version_to_rollback"
  
#   # The following assumes a single file rollback. If multiple files constitute a version, include them in the rollback process.
#   echo "Downloading $rollback_url ..."
#   curl -L "$rollback_url" -o "fossa_${version_to_rollback}_darwin_amd64.zip"
  
#   echo "Uploading to Artifactory..."
#   curl -H "Authorization: Bearer $ACCESS_TOKEN" -T "fossa_${version_to_rollback}_darwin_amd64.zip" "$ARTIFACTORY_URL/$REPOSITORY_NAME/fossa_${version_to_rollback}_darwin_amd64.zip"

#   echo "Rollback to $version_to_rollback completed."
# }

# # Main logic: List available versions and prompt for rollback version
# echo "Fetching available versions from GitHub..."
# versions=$(fetch_versions_from_rss)
# echo "Available versions:"
# echo "$versions"

# # Prompt for user input on which version to roll back to
# read -p "Enter the version to roll back to: " version_to_rollback

# # Call rollback function with user-specified version
# rollback_to_version "$version_to_rollback"
