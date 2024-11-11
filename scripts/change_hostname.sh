#!/bin/bash

# Validate the hostname
validate_hostname() {
    local hostname=$1
    if [[ $hostname =~ ^[a-zA-Z0-9][-a-zA-Z0-9]*$ ]]; then
        return 0
    else
        echo "Invalid hostname. It can only contain letters, numbers, and hyphens."
        return 1
    fi
}

# Change the hostname
change_hostname() {
    local new_hostname=$1

    # Backup current hostname files
    sudo cp /etc/hostname /etc/hostname.bak
    sudo cp /etc/hosts /etc/hosts.bak

    # Update hostname
    echo "$new_hostname" | sudo tee /etc/hostname
    sudo sed -i "s/$(hostname)/$new_hostname/g" /etc/hosts
    sudo hostnamectl set-hostname "$new_hostname"

    echo "Hostname changed to $new_hostname"
    echo "Backup files: /etc/hostname.bak, /etc/hosts.bak"
}

# Main script
echo "Current hostname: $(hostname)"
read -p "Enter the new hostname: " new_hostname

if validate_hostname "$new_hostname"; then
    change_hostname "$new_hostname"
else
    echo "Invalid input. Aborting."
    exit 1
fi

# Optional reboot
read -p "Reboot now? (y/n): " reboot_choice
if [[ $reboot_choice =~ ^[Yy]$ ]]; then
    echo "Rebooting..."
    sudo reboot
else
    echo "Reboot later to apply changes."
fi