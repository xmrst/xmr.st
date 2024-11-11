#!/bin/bash

# Automatically fetch the local user's username
USERNAME=$(whoami)

# Prompt for Vaultwarden server URL, email, password, and export password
read -p "Enter your Vaultwarden server URL (e.g., https://vaultwarden.example.com): " VAULTWARDEN_SERVER
read -p "Enter your Bitwarden email: " BW_EMAIL
read -s -p "Enter your Bitwarden password: " BW_PASSWORD
echo
read -s -p "Enter the password for export file encryption: " EXPORT_PASSWORD
echo

# Install required packages
sudo apt update && sudo apt install -y snapd jq
sudo snap install bw

# Ensure /snap/bin is in the PATH
if ! echo "$PATH" | grep -q "/snap/bin"; then
  export PATH="$PATH:/snap/bin"
  echo 'export PATH=$PATH:/snap/bin' >> ~/.bashrc
fi

# Create necessary directories
mkdir -p /home/$USERNAME/vaultwarden/scripts
mkdir -p /home/$USERNAME/vaultwarden/exports
mkdir -p /home/$USERNAME/vaultwarden/tmp  # Temporary file directory

# Configure Vaultwarden server and confirm
/snap/bin/bw logout >/dev/null 2>&1  # Force logout before setting server
/snap/bin/bw config server "$VAULTWARDEN_SERVER"
/snap/bin/bw config server | grep -q "$VAULTWARDEN_SERVER" || { echo "Failed to set server URL"; exit 1; }

# Create the backup script
cat << EOF > /home/$USERNAME/vaultwarden/scripts/bitwarden_backup.sh
#!/bin/bash

export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/snap/bin

# Setup logging
LOGFILE="\$HOME/vaultwarden/scripts/bitwarden_backup.log"
exec > >(tee -a \$LOGFILE) 2>&1

echo "=== \$(date) ==="
echo "Starting Vaultwarden backup process..."

# Bitwarden credentials
export BW_EMAIL="$BW_EMAIL"
export BW_PASSWORD="$BW_PASSWORD"
EXPORT_PASSWORD="$EXPORT_PASSWORD"

# Force logout to avoid existing sessions
/snap/bin/bw logout >/dev/null 2>&1

# Login to Bitwarden and get session key
BW_SESSION=\$(/snap/bin/bw login --raw --passwordenv BW_PASSWORD \$BW_EMAIL)
if [ \$? -ne 0 ]; then
  echo "[\$(date)] Error: Failed to login to Bitwarden."
  exit 1
fi
echo "[\$(date)] Successfully logged into Bitwarden."
export BW_SESSION

# Unlock the vault and handle permissions
echo "\$BW_PASSWORD" | /snap/bin/bw unlock --raw --passwordenv BW_PASSWORD --session "\$BW_SESSION" > "\$HOME/vaultwarden/tmp/bw_session_unlocked" 2>/dev/null
if [ \$? -ne 0 ]; then
  echo "[\$(date)] Error: Failed to unlock Bitwarden vault."
  exit 1
fi
echo "[\$(date)] Vault unlocked successfully."
BW_SESSION=\$(cat "\$HOME/vaultwarden/tmp/bw_session_unlocked")

# Export the vault with password protection
/snap/bin/bw export --format encrypted_json --raw > "\$HOME/vaultwarden/exports/vaultwarden-backup.json" --password "\$EXPORT_PASSWORD" --session "\$BW_SESSION" 2>/dev/null
if [ \$? -ne 0 ]; then
  echo "[\$(date)] Error: Failed to export Bitwarden vault."
  exit 1
fi
echo "[\$(date)] Vault exported successfully to \$HOME/vaultwarden/exports/vaultwarden-backup.json."

# Logout from Bitwarden
/snap/bin/bw logout --session "\$BW_SESSION" >/dev/null 2>&1
if [ \$? -ne 0 ]; then
  echo "[\$(date)] Error: Failed to log out from Bitwarden."
  exit 1
fi
echo "[\$(date)] Successfully logged out from Bitwarden."

# Cleanup
rm -f "\$HOME/vaultwarden/tmp/bw_session_unlocked"
echo "[\$(date)] Cleanup completed."

echo "Backup process finished successfully."
EOF

# Make the script executable
chmod +x /home/$USERNAME/vaultwarden/scripts/bitwarden_backup.sh

# Secure the backup location
chmod 700 /home/$USERNAME/vaultwarden/exports

# Add the cron job to automate the backup
(crontab -l 2>/dev/null; echo "* * * * * /home/$USERNAME/vaultwarden/scripts/bitwarden_backup.sh >> /home/$USERNAME/vaultwarden/scripts/bitwarden_backup_cron.log 2>&1") | crontab -

# Verify the cron job has been saved
if crontab -l | grep -q "/home/$USERNAME/vaultwarden/scripts/bitwarden_backup.sh"; then
    echo "Cron job added successfully."
else
    echo "Error: Failed to add cron job."
    exit 1
fi

# Instructions for monitoring the backup process
echo "To monitor the backup process, check the cron logs using:"
echo "sudo journalctl | grep CRON"
echo ""
echo "Review the log file:"
echo "cat /home/$USERNAME/vaultwarden/scripts/bitwarden_backup_cron.log"
