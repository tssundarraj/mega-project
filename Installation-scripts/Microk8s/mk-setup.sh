#!/bin/bash

set -e

# Install MicroK8s
echo "Installing MicroK8s..."
sudo apt update
sudo snap install microk8s --classic

# Add the current user to 'microk8s' group
echo "Adding user '$USER' to 'microk8s' group..."
sudo usermod -aG microk8s ubuntu

# Change ownership of .kube directory
echo "Setting permissions for .kube directory..."
sudo chown -f -R $USER ~/.kube || true

# Refresh group membership without logout/login
echo "Refreshing group membership..."
newgrp microk8s << END
echo "Group refreshed. Verifying MicroK8s status..."
microk8s status --wait-ready
END

echo "✅ MicroK8s installed and ready!"
mk get all --all-namepaces