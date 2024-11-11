#!/bin/bash

# Update the package list to ensure we have the latest information on available packages
sudo apt update

# Install prerequisites for Docker, such as packages for secure APT and transport protocols
sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release

# Add Dockerâ€™s official GPG key for package verification
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Add Dockerâ€™s official repository to the APT sources list
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update the package list again to include Docker packages from the newly added repository
sudo apt update

# Install Docker Engine, CLI, and containerd packages
sudo apt install -y docker-ce docker-ce-cli containerd.io

# Install Docker Compose from the official GitHub repository
# Fetch the latest version number dynamically from the GitHub API and download the corresponding binary
sudo curl -L "https://github.com/docker/compose/releases/download/$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep -oP '(?<=tag_name\": \")[0-9a-zA-Z.-]+')" -o /usr/local/bin/docker-compose

# Apply executable permissions to the Docker Compose binary
sudo chmod +x /usr/local/bin/docker-compose

# Create a Docker group to allow running Docker commands without sudo
sudo groupadd docker

# Add the current user to the Docker group
sudo usermod -aG docker $USER

# Pull the latest Portainer image from the Docker Hub
sudo docker pull portainer/portainer-ce:latest

# Create a Docker volume for Portainer data
sudo docker volume create portainer_data

# Create and start a Portainer container
# Portainer will be accessible on port 9000 and will restart automatically if the system reboots
sudo docker run -d -p 9000:9000 --name portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce:latest

# Print installation details to the terminal
echo "Docker, Docker Compose, and Portainer have been installed."
echo "Portainer is accessible on port 9000."

# Inform the user to log out and log back in for the Docker group membership changes to take effect
echo "Please log out and log back in to apply the Docker group membership changes."
            