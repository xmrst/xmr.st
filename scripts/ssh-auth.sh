#!/bin/bash

# This script sets up SSH key-based authentication on a server.
# Usage:
# ./setup_ssh_key_auth.sh -u username -k "public_key"

# Ensure the script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root."
  exit 1
fi

# Parse command-line arguments
while getopts u:k: flag; do
  case "${flag}" in
    u) USERNAME=${OPTARG} ;;
    k) PUB_KEY=${OPTARG} ;;
    *) echo "Invalid option"; exit 1 ;;
  esac
done

# Check if username and public key are provided
if [ -z "$USERNAME" ] || [ -z "$PUB_KEY" ]; then
  echo "Usage: $0 -u username -k \"public_key\""
  exit 1
fi

# Step 1: Install OpenSSH Server
echo "Installing OpenSSH Server..."
apt-get update
apt-get install -y openssh-server

# Step 2: Add Public Key to the Server

# Check if user exists
if id "$USERNAME" &>/dev/null; then
  echo "User $USERNAME exists."
else
  echo "User $USERNAME does not exist. Exiting."
  exit 1
fi

# Ensure the user's home directory exists
USER_HOME=$(eval echo "~$USERNAME")

# Create .ssh directory if it doesn't exist
if [ ! -d "$USER_HOME/.ssh" ]; then
  mkdir "$USER_HOME/.ssh"
  chown "$USERNAME":"$USERNAME" "$USER_HOME/.ssh"
  chmod 700 "$USER_HOME/.ssh"
fi

# Add the public key to authorized_keys
echo "$PUB_KEY" >> "$USER_HOME/.ssh/authorized_keys"
chown "$USERNAME":"$USERNAME" "$USER_HOME/.ssh/authorized_keys"
chmod 600 "$USER_HOME/.ssh/authorized_keys"

# Step 3: Configure SSH Daemon
echo "Configuring SSH daemon..."

# Backup the original sshd_config
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak

# Modify sshd_config
SSHD_CONFIG="/etc/ssh/sshd_config"

# Update or add configuration options
sed -i 's/^#*PermitRootLogin.*/PermitRootLogin prohibit-password/' "$SSHD_CONFIG"
sed -i 's/^#*PubkeyAuthentication.*/PubkeyAuthentication yes/' "$SSHD_CONFIG"
sed -i 's@^#*AuthorizedKeysFile.*@AuthorizedKeysFile .ssh/authorized_keys@' "$SSHD_CONFIG"
sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication no/' "$SSHD_CONFIG"
sed -i 's/^#*ChallengeResponseAuthentication.*/ChallengeResponseAuthentication no/' "$SSHD_CONFIG"
sed -i 's/^#*UsePAM.*/UsePAM no/' "$SSHD_CONFIG"

# Step 4: Restart SSH Service
echo "Restarting SSH service..."
systemctl restart sshd

echo "SSH key-based authentication setup is complete."
