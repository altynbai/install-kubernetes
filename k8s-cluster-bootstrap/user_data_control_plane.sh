#!/bin/bash

set -eE

# Log output
exec > >(tee -a /var/log/user-data.log)
exec 2>&1

echo "=== Starting Control Plane Installation ==="
echo "Timestamp: $(date)"

# Update package manager
apt-get update
apt-get install -y git

# Clone the installation repository
cd /opt
git clone https://github.com/ccollicutt/install-kubernetes || true
cd /opt/install-kubernetes

# Copy the install script (it should already be there from git clone)
# but we ensure it has execution permissions
chmod +x install-kubernetes-cilium.sh

echo "=== Starting Kubernetes Installation on Control Plane ==="
# Run the installation script with control plane flag
./install-kubernetes-cilium.sh -c

echo "=== Control Plane Installation Complete ==="
echo "Timestamp: $(date)"

# Signal completion
touch /opt/control-plane-ready.txt
