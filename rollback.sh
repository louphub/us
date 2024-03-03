#!/bin/bash

# JFrog Artifactory details
ARTIFACTORY_URL="https://louphub.jfrog.io/artifactory"
REPOSITORY_NAME="fossa-generic-local"

# Function to roll back to a specific version
rollback_to_version() {
    local version_to_rollback=$1
    local release_directory="$REPOSITORY_NAME/releases/$version_to_rollback"
    
    echo "Starting rollback to version: $version_to_rollback"

    # Fetch the release data
    release_data=$(curl -s "https://api.github.com/repos/fossas/fossa-cli/releases/tags/v$version_to_rollback")
    
    # Check if the release data is valid
    if [ -z "$release_data" ] || ! echo "$release_data" | jq . > /dev/null 2>&1; then
        echo "Failed to fetch release data or data is invalid. Exiting..."
        exit 1
    fi

    # Extract assets URLs
    assets_urls=$(echo "$release_data" | jq -r '.assets[].browser_download_url')

    # Check if no assets were found
    if [ -z "$assets_urls" ] || [ "$assets_urls" == "null" ]; then
        echo "No assets found for version $version_to_rollback. Exiting..."
        exit 1
    fi

    # Iterate over each asset and process it
    for url in $assets_urls; do
        if [ -z "$url" ] || [ "$url" == "null" ]; then
            echo "Invalid asset URL encountered. Skipping..."
            continue
        fi

        local file_name=$(basename "$url")
        
        echo "Downloading $file_name ..."
        if ! curl -L "$url" -o "$file_name"; then
            echo "Failed to download $file_name from $url. Exiting..."
            exit 1
        fi

        local upload_path="$ARTIFACTORY_URL/$release_directory/$file_name"

        echo "Uploading $file_name to Artifactory at $upload_path..."
        if ! curl -H "Authorization: Bearer ${ACCESS_TOKEN}" -T "$file_name" "$upload_path"; then
            echo "Failed to upload $file_name to Artifactory. Exiting..."
            rm "$file_name"  # Clean up the downloaded file
            exit 1
        fi

        echo "Successfully uploaded $file_name to Artifactory."
        rm "$file_name"  # Clean up after successful upload
    done

    echo "Rollback to $version_to_rollback completed successfully."
}

# Main execution block
if [ -z "$1" ]; then
    echo "No version specified for the rollback. Please provide a version number as an argument."
    exit 1
else
    rollback_to_version "$1"
fi
