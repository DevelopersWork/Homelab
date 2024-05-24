#!/bin/bash

# Get docker user and group information (ensuring they exist)
PUID=$(getent passwd docker | cut -d: -f3) || { echo "Docker user not found."; exit 1; }
PGID=$(getent group docker | cut -d: -f3) || { echo "Docker group not found."; exit 1; }

# Ensure script is running as docker, exit if not 
if [ "$(id -u)" -ne "$PUID" ] || [ "$(id -g)" -ne "$PGID" ]; then
  echo "This script must be run as the 'docker' user."
  exit 1
fi

# Source the utils.sh script to import the function
# Assuming utils.sh is in the bash-scripts directory relative to this script
source ./bash-scripts/utils.sh || { echo "Failed to source utils.sh"; exit 1; } 

# Data and Volumes Configuration
DOCKER_VOLUME_DIR="/home/docker"

# Get current timestamp
timestamp=$(date +%s)

# Define volume and container names with timestamps
PORTAINER_NAME="portainer-$timestamp"

# Stop existing Portainer containers
echo "Checking for existing Portainer containers..."
stop_containers_with_image_base "portainer/portainer-ce"

# Create Portainer Volume
echo "Creating Portainer volume..."
docker volume create "$PORTAINER_NAME" || { echo "Failed to create Portainer volume."; exit 1; }

# Run Portainer Container
echo "Running Portainer container..."
docker run -d -u "$PUID:$PGID" -p 9000:9000 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v "/etc/timezone:/etc/timezone:ro" \
  -v "$PORTAINER_NAME:/data" \
  --name "$PORTAINER_NAME" \
  --restart=always \
  --cpus="0.2" \
  --memory="256m" \
  portainer/portainer-ce:2.20.2 || { echo "Failed to start Portainer container."; exit 1; }
