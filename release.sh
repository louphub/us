#!/bin/bash

# JFrog Artifactory details
ARTIFACTORY_URL="https://louphub.jfrog.io/artifactory"
REPOSITORY_NAME="fossa-generic-local"

# Validate if necessary environment variables are set
if [[ -z "${ACCESS_TOKEN}" || -z "${TEAMS_WEBHOOK_URL}" ]]; then
    echo "Required environment variables are not set. Exiting..."
    exit 1
fi

# Function to extract the latest version in Artifactory
get_latest_artifactory_version() {
    echo "Fetching the latest version from Artifactory..."
    curl -s -H "Authorization: Bearer ${ACCESS_TOKEN}" "$ARTIFACTORY_URL/api/storage/$REPOSITORY_NAME?list&deep=1&listFolders=1&mdTimestamps=1" |
    jq -r '.files[] | select(.uri | endswith("_darwin_amd64.zip")) | .uri' |
    sed 's|.*/fossa_||; s|_darwin_amd64.zip||' |
    sort -V |
    tail -1
}

# Function to get the latest GitHub release version from RSS feed
get_latest_github_version() {
    echo "Fetching the latest version from the FOSSA CLI GitHub RSS feed..."
    curl -s "https://github.com/fossas/fossa-cli/releases.atom" |
    awk 'BEGIN { RS = "<entry>" ; FS = "<title>" } NR>1 { print $2 }' | 
    sed -n 's/.*v\([0-9.]*\).*/\1/p' |
    sort -V | 
    tail -1
}

# Function to download and upload a file to Artifactory
upload_to_artifactory() {
    local file_url=$1
    local file_name=$(basename "$file_url")

    echo "Downloading $file_name..."
    curl -L "$file_url" -o "$file_name"

    if [ ! -f "$file_name" ]; then
        echo "Failed to download $file_name. Exiting..."
        exit 1
    fi

    echo "Uploading $file_name to Artifactory..."
    curl -H "Authorization: Bearer ${ACCESS_TOKEN}" -T "$file_name" "$ARTIFACTORY_URL/$REPOSITORY_NAME/$file_name"

    if [ $? -ne 0 ]; then
        echo "Failed to upload $file_name to Artifactory. Exiting..."
        rm "$file_name"
        exit 1
    fi

    echo "Uploaded $file_name successfully to Artifactory."
    rm "$file_name"
}

# Main logic
echo "Starting FOSSA CLI version check and update process..."

latest_artifactory_version=$(get_latest_artifactory_version)
latest_github_version=$(get_latest_github_version)

echo "Latest Artifactory version: $latest_artifactory_version"
echo "Latest GitHub version: $latest_github_version"

if [ "$latest_github_version" != "$latest_artifactory_version" ]; then
    echo "New FOSSA CLI version detected: $latest_github_version"

    # Send alert to Teams channel
    message="New FOSSA CLI version $latest_github_version is available. Updating Artifactory..."
    curl -H 'Content-Type: application/json' -d "{\"text\": \"$message\"}" "${TEAMS_WEBHOOK_URL}"
    
    # Fetch and upload all assets
    echo "Fetching assets for version $latest_github_version..."
    assets_urls=$(curl -s "https://api.github.com/repos/fossas/fossa-cli/releases/tags/v$latest_github_version" | jq -r '.assets[].browser_download_url')
    
    for url in $assets_urls; do
        upload_to_artifactory "$url"
    done

    echo "All new assets have been uploaded to Artifactory."
else
    echo "Artifactory is up to date with the latest FOSSA CLI version."
fi


# #!/bin/bash

# # JFrog Artifactory details
# ARTIFACTORY_URL="https://louphub.jfrog.io/artifactory"
# REPOSITORY_NAME="fossa-generic-local"
# # Ensure the ACCESS_TOKEN is set as an environment variable for security
# ACCESS_TOKEN="${ACCESS_TOKEN}"

# # Teams webhook URL
# # Ensure the TEAMS_WEBHOOK_URL is set as an environment variable for security
# TEAMS_WEBHOOK_URL="${TEAMS_WEBHOOK_URL}"

# # Function to extract the latest version in Artifactory
# get_latest_artifactory_version() {
#     curl -s -H "Authorization: Bearer $ACCESS_TOKEN" "$ARTIFACTORY_URL/api/storage/$REPOSITORY_NAME?list&deep=1&listFolders=1&mdTimestamps=1" |
#     jq -r '.files[] | select(.uri | endswith("_darwin_amd64.zip")) | .uri' |
#     sed 's|.*/fossa_||; s|_darwin_amd64.zip||' |
#     sort -V |
#     tail -1
# }

# # Function to get the latest GitHub release version from RSS feed
# get_latest_github_version() {
#     curl -s "https://github.com/fossas/fossa-cli/releases.atom" |
#     awk 'BEGIN { RS = "<entry>" ; FS = "<title>" } NR>1 { print $2 }' | 
#     sed -n 's/.*v\([0-9.]*\).*/\1/p' |
#     sort -V | 
#     tail -1
# }

# # Function to download and upload a file to Artifactory
# upload_to_artifactory() {
#     local file_url=$1
#     local file_name=$(basename "$file_url")

#     echo "Downloading $file_name..."
#     curl -L "$file_url" -o "$file_name"

#     # Check if the file was downloaded successfully
#     if [ ! -f "$file_name" ]; then
#         echo "Failed to download $file_name"
#         exit 1
#     fi

#     echo "Uploading $file_name to Artifactory..."
#     curl -H "Authorization: Bearer $ACCESS_TOKEN" -T "$file_name" "$ARTIFACTORY_URL/$REPOSITORY_NAME/$file_name"

#     # Check if the upload was successful
#     if [ $? -ne 0 ]; then
#         echo "Failed to upload $file_name to Artifactory"
#         rm "$file_name"
#         exit 1
#     fi

#     echo "Uploaded $file_name successfully to Artifactory."
#     rm "$file_name"
# }

# # Main logic
# latest_artifactory_version=$(get_latest_artifactory_version)
# latest_github_version=$(get_latest_github_version)

# echo "Latest Artifactory version: $latest_artifactory_version"
# echo "Latest GitHub version: $latest_github_version"

# if [ "$latest_github_version" != "$latest_artifactory_version" ]; then
#     echo "New FOSSA CLI version detected: $latest_github_version"

#     # Send alert to Teams channel
#     message="New FOSSA CLI version $latest_github_version is available. Updating Artifactory..."
#     curl -H 'Content-Type: application/json' -d "{\"text\": \"$message\"}" $TEAMS_WEBHOOK_URL
    
#     # Fetch and upload all assets
#     assets_urls=$(curl -s "https://api.github.com/repos/fossas/fossa-cli/releases/tags/v$latest_github_version" | jq -r '.assets[].browser_download_url')
    
#     for url in $assets_urls; do
#         upload_to_artifactory "$url"
#     done

#     echo "All new assets have been uploaded to Artifactory."
# else
#     echo "No new FOSSA CLI version found. Artifactory is up to date."
# fi
