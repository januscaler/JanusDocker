#!/bin/bash

# Create and set up the buildx builder
docker buildx create --name multi-arch \
  --platform "linux/arm64,linux/amd64,linux/arm/v7,windows/amd64" \
  --driver "docker-container" --use

# Define image name
IMAGE_NAME="shivanshtalwar0/janus-gateway"

# Define platforms
PLATFORMS=("linux/amd64" "linux/arm/v7" "linux/arm64" "linux/amd64" "linux/arm/v7" "windows/amd64")

# Loop through each platform and build the image
for PLATFORM in "${PLATFORMS[@]}"; do
    echo "Building for platform: $PLATFORM"

    # Replace slashes with dashes for valid tag format
    TAG="${PLATFORM//\//-}"
    
    if [[ $PLATFORM == windows/* ]]; then
        # For Windows builds, use a different base image if necessary
        docker buildx build --platform "$PLATFORM" \
            --push \
            --build-arg PLATFORM="$PLATFORM" \
            --build-arg UBUNTU_VERSION=20.04 \
            -t "$IMAGE_NAME:$TAG" .
    else
        # For Linux builds
        docker buildx build --platform "$PLATFORM" \
            --push \
            --build-arg PLATFORM="$PLATFORM" \
            --build-arg UBUNTU_VERSION=24.04 \
            -t "$IMAGE_NAME:$TAG" .
    fi
done

echo "Builds completed."
