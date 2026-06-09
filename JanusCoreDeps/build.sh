#!/bin/bash

# 1. Create and set up the buildx builder 
# Added fallback to 'use' if it already exists from a previous run
docker buildx create --name multi-arch \
  --platform "linux/arm64,linux/amd64,linux/arm/v7" \
  --driver "docker-container" --use || docker buildx use multi-arch

# Define image name
IMAGE_NAME="shivanshtalwar0/januscoredeps-alpine"

# Define platforms
PLATFORMS=("linux/amd64" "linux/arm64" "linux/arm/v7" )

# Loop through each platform and build the image
for PLATFORM in "${PLATFORMS[@]}"; do
    echo "Building for platform: $PLATFORM"

    # Replace slashes with dashes for valid tag format (e.g., linux-amd64)
    TAG="${PLATFORM//\//-}"
    
    # Build and push the Alpine image
    docker buildx build --platform "$PLATFORM" \
        --push \
        --build-arg PLATFORM="$PLATFORM" \
        -t "$IMAGE_NAME:$TAG" .
done

echo "Builds completed."
