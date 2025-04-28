#!/bin/bash

# Jenkins Installation Script for Ubuntu Server
# Make sure to run this as root or with sudo

set -e

echo "🔄 Updating system packages..."
sudo apt update && sudo apt upgrade -y

echo "☕ Checking if Java is installed..."
if ! java -version &>/dev/null; then
    echo "☕ Installing Java (OpenJDK 11)..."
    sudo apt install openjdk-11-jdk -y
else
    echo "✅ Java is already installed."
fi

echo "✅ Verifying Java installation..."
java -version

echo "📦 Adding Jenkins repository and key..."
wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" | sudo tee /etc/apt/sources.list.d/jenkins.list

echo "🔄 Updating package index..."
sudo apt update

echo "📥 Installing Jenkins..."
sudo apt install jenkins -y

echo "🚀 Starting and enabling Jenkins service..."
sudo systemctl enable jenkins
sudo systemctl start jenkins

echo "🔍 Checking Jenkins status..."
sudo systemctl status jenkins --no-pager

echo "🌐 Jenkins installation complete!"
echo "📝 Access Jenkins at: http://<your-server-ip>:8080"
echo "🔑 Initial Admin Password:"
sudo cat /var/lib/jenkins/secrets/initialAdminPassword