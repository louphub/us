#!/bin/bash

# URL of the FOSSA CLI releases RSS feed
FEED_URL="https://github.com/fossas/fossa-cli/releases.atom"

# File where the last checked version is stored
VERSION_FILE="last_release.txt"

# Fetch the latest release version from the RSS feed
# The awk command extracts the content of the first <title> tag after skipping the first (feed title)
LATEST_VERSION=$(curl -s $FEED_URL | awk 'BEGIN{RS="<entry>"; FS="<title>|</title>"} NR==2 {print $2}')

# Check if the VERSION_FILE exists and read the last known version
if [ -f "$VERSION_FILE" ]; then
    LAST_VERSION=$(cat "$VERSION_FILE")
else
    echo "No last release version found. Creating $VERSION_FILE."
    echo "none" > "$VERSION_FILE"
    LAST_VERSION="none"
fi

echo "Latest release version: $LATEST_VERSION"
echo "Last known release version: $LAST_VERSION"

# Compare the latest release with the last known release
if [ "$LATEST_VERSION" != "$LAST_VERSION" ]; then
    echo "New release detected: $LATEST_VERSION"
    # Update the version file with the latest version
    echo $LATEST_VERSION > "$VERSION_FILE"
else
    echo "Already up to date with version $LAST_VERSION."
fi
