#!/bin/bash

# Get docker user and group information (ensuring they exist)
PUID=$(getent passwd docker | cut -d: -f3) || { echo "Docker user not found."; exit 1; }
PGID=$(getent group docker | cut -d: -f3) || { echo "Docker group not found."; exit 1; }

# Ensure script is running as the 'docker' user
if [ "$(id -u)" -ne "$PUID" ] || [ "$(id -g)" -ne "$PGID" ]; then
  echo "This script must be run as the 'docker' user."
  exit 1
fi

# Function to remove containers with a specific image base (ignoring tag)
function remove_containers_with_image_base() {
  local image_base=$1
  container_ids=$(docker ps --no-trunc | grep "$image_base" | awk '{ print $1 }')

  if [ -n "$container_ids" ]; then
    echo "Stopping existing containers with image base: $image_base"
    docker container stop $container_ids
    docker container rm $container_ids
  fi
}

# Remove existing Portainer containers
echo "Checking for existing Portainer containers..."
remove_containers_with_image_base "portainer/portainer-ce"

# Data and Volumes Configuration
PORTAINER_VOLUME_PATH="/home/docker/volumes/portainer"

# Create the Portainer volume directory
echo "Creating Portainer volume directory..."
mkdir -p "$PORTAINER_VOLUME_PATH" || { echo "Failed to create Portainer volume directory."; exit 1; }

# Set permissions on the Portainer volume directory
chown -R "$PUID:$PGID" "$PORTAINER_VOLUME_PATH" 

# Run Portainer Container
echo "Running Portainer container..."
docker run -d -u "$PUID:$PGID" -p 9000:9000 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v "/etc/timezone:/etc/timezone:ro" \
  -v "$PORTAINER_VOLUME_PATH:/data" \
  --name portainer \
  --restart="unless-stopped" \
  --cpus="0.2" \
  --memory="256m" \
  portainer/portainer-ce:2.20.2 || { echo "Failed to start Portainer container."; exit 1; }
