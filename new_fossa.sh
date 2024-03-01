#!/bin/bash

# Set the GitHub API URL for FOSSA CLI releases
GITHUB_API_URL="https://api.github.com/repos/fossas/fossa-cli/releases/latest"

# Directory to store the downloaded files
DOWNLOAD_DIR="test_fossa"

# Create the directory if it doesn't exist
mkdir -p "$DOWNLOAD_DIR"

# Fetch the latest release data from GitHub
release_data=$(curl -s $GITHUB_API_URL)

# Check if jq is installed
if ! command -v jq &> /dev/null
then
    echo "jq could not be found, please install it to proceed."
    exit 1
fi

# Download only the specified assets using cURL
echo "Downloading specified assets..."

# Parse and download each required asset
echo $release_data | jq -r '.assets[] | select(.name | test("^fossa_.*_(darwin_amd64\\.zip|linux_amd64\\.(tar\\.gz|zip)|windows_amd64\\.zip)(\\.sha256)?$")) | .browser_download_url' | while read -r url; do
    echo "Downloading $url..."
    curl -L "$url" -o "$DOWNLOAD_DIR/$(basename $url)"
done

echo "Download completed. Files are saved in $DOWNLOAD_DIR."
