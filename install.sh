#!/bin/bash

set -e

# Prompt for username, password and GitHub repo URL
read -p "Enter username to create: " USERNAME
read -sp "Enter password for $USERNAME: " PASSWORD
echo
read -p "Enter GitHub repo URL to clone: " GITHUB_REPO

# Update and upgrade system packages
echo "Updating and upgrading system packages..."
sudo apt update -y && sudo apt upgrade -y

# Create new user and set password
echo "Creating user $USERNAME..."
sudo adduser --disabled-password --gecos "" $USERNAME
echo "$USERNAME:$PASSWORD" | sudo chpasswd
sudo usermod -aG sudo $USERNAME

# Setup basic firewall (ufw)
echo "Installing and enabling UFW firewall..."
sudo apt install -y ufw
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow OpenSSH
sudo ufw --force enable

# Install essential packages: curl, git, vim, docker, python3, pip
echo "Installing essential packages..."
sudo apt install -y curl git vim docker.io python3 python3-pip python3-apt
pip3 install python-on-whales
sudo systemctl enable --now docker
sudo usermod -aG docker $USERNAME

# Generate SSH key pair for the new user (no passphrase for automation)
echo "Generating SSH key pair for user $USERNAME..."
sudo -u $USERNAME mkdir -p /home/$USERNAME/.ssh
sudo -u $USERNAME ssh-keygen -t rsa -b 4096 -N "" -f /home/$USERNAME/.ssh/id_rsa

# Set authorized_keys to include the public key to enable key-based authentication
sudo cp /home/$USERNAME/.ssh/id_rsa.pub /home/$USERNAME/.ssh/authorized_keys
sudo chown -R $USERNAME:$USERNAME /home/$USERNAME/.ssh
sudo chmod 700 /home/$USERNAME/.ssh
sudo chmod 600 /home/$USERNAME/.ssh/authorized_keys

# Clone GitHub repo and run install.py as the new user
echo "Cloning GitHub repo and running install.py script..."
sudo -u $USERNAME bash -c "
  git clone $GITHUB_REPO /home/$USERNAME/repo
  cd /home/$USERNAME/repo
  python3 install.py
"

echo "Setup complete."
echo "SSH private key for user $USERNAME is located at /home/$USERNAME/.ssh/id_rsa"
