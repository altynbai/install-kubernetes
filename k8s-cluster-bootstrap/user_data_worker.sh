#!/bin/bash

set -eE

# Log output
exec > >(tee -a /var/log/user-data.log)
exec 2>&1

echo "=== Starting Worker Node Installation ==="
echo "Timestamp: $(date)"
echo "Control plane IP: ${control_plane_public_ip}"

# Update package manager
apt-get update
apt-get install -y git curl

# Clone the installation repository
cd /opt
git clone https://github.com/ccollicutt/install-kubernetes || true
cd /opt/install-kubernetes

# Copy the install script (it should already be there from git clone)
# but we ensure it has execution permissions
chmod +x install-kubernetes-cilium.sh

echo "=== Waiting for Control Plane to be ready ==="

# Wait for control plane to be ready by checking if it's accessible
MAX_ATTEMPTS=60
ATTEMPT=0
CONTROL_PLANE_READY=false

while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
  if curl -sk https://${control_plane_public_ip}:6443/version > /dev/null 2>&1; then
    echo "Control plane is ready!"
    CONTROL_PLANE_READY=true
    break
  fi

  ATTEMPT=$((ATTEMPT + 1))
  echo "Waiting for control plane... (Attempt $ATTEMPT/$MAX_ATTEMPTS)"
  sleep 10
done

if [ "$CONTROL_PLANE_READY" = false ]; then
  echo "ERROR: Control plane did not become ready in time"
  exit 1
fi

echo "=== Starting Kubernetes Installation on Worker Node ==="
# Run the installation script without control plane flag (worker node)
./install-kubernetes-cilium.sh

echo "=== Worker Installation Complete (before joining cluster) ==="
echo "Timestamp: $(date)"

# Wait for the join command from control plane
echo "=== Waiting for join command from control plane ==="

# Get the join command from control plane
MAX_ATTEMPTS=30
ATTEMPT=0
JOIN_COMMAND=""

while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
  # Try to get the join command from the control plane
  # We use kubectl on the control plane to get the token
  JOIN_COMMAND=$(ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    ubuntu@${control_plane_public_ip} \
    'kubeadm token create --print-join-command --ttl 0' 2>/dev/null || echo "")

  if [ -n "$JOIN_COMMAND" ]; then
    echo "Join command received: $JOIN_COMMAND"
    break
  fi

  ATTEMPT=$((ATTEMPT + 1))
  echo "Waiting for join command... (Attempt $ATTEMPT/$MAX_ATTEMPTS)"
  sleep 10
done

if [ -z "$JOIN_COMMAND" ]; then
  echo "ERROR: Could not obtain join command from control plane"
  exit 1
fi

echo "=== Joining worker node to cluster ==="
# Execute the join command
eval "$JOIN_COMMAND"

echo "=== Worker Node Successfully Joined Cluster ==="
echo "Timestamp: $(date)"

# Signal completion
touch /opt/worker-ready.txt
