#!/bin/bash

# JFrog Artifactory details
ARTIFACTORY_URL="https://louphub.jfrog.io/artifactory"
REPOSITORY_NAME="fossa-generic-local"

# Validate if necessary environment variables are set
if [[ -z "${ACCESS_TOKEN}" ]]; then
    echo "ACCESS_TOKEN environment variable is not set. Exiting..."
    exit 1
fi

# Function to roll back to a specific version
rollback_to_version() {
    local version_to_rollback=$1
    
    echo "Starting rollback to version: $version_to_rollback"

    # Fetch assets for the specified version
    assets_urls=$(curl -s "https://api.github.com/repos/fossas/fossa-cli/releases/tags/v$version_to_rollback" | jq -r '.assets[].browser_download_url')
    
    # Check if no assets were found
    if [ -z "$assets_urls" ] || [ "$assets_urls" == "null" ]; then
        echo "No assets found for version $version_to_rollback. Exiting..."
        exit 1
    fi

    # Iterate over each asset and process it
    for url in $assets_urls; do
        local file_name=$(basename "$url")
        
        echo "Downloading $file_name ..."
        if ! curl -L "$url" -o "$file_name"; then
            echo "Failed to download $file_name from $url. Exiting..."
            exit 1
        fi

        echo "Uploading $file_name to Artifactory..."
        if ! curl -H "Authorization: Bearer $ACCESS_TOKEN" -T "$file_name" "$ARTIFACTORY_URL/$REPOSITORY_NAME/$file_name"; then
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
