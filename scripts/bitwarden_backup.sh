#!/bin/bash

export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/snap/bin

# Setup logging
LOGFILE="$HOME/vaultwarden/scripts/bitwarden_backup.log"
exec > >(tee -a $LOGFILE) 2>&1

echo "=== $(date) ==="
echo "Starting Vaultwarden backup process..."

# Bitwarden credentials
export BW_EMAIL="changeme"
export BW_PASSWORD="changeme"
EXPORT_PASSWORD="changeme"

# Login to Bitwarden and get session key
BW_SESSION=$(bw login --raw --passwordenv BW_PASSWORD $BW_EMAIL)
if [ $? -ne 0 ]; then
  echo "[$(date)] Error: Failed to login to Bitwarden."
  exit 1
fi
echo "[$(date)] Successfully logged into Bitwarden."
export BW_SESSION

# Unlock the vault
echo $BW_PASSWORD | bw unlock --raw --passwordenv BW_PASSWORD --session $BW_SESSION > /tmp/bw_session_unlocked
if [ $? -ne 0 ]; then
  echo "[$(date)] Error: Failed to unlock Bitwarden vault."
  exit 1
fi
echo "[$(date)] Vault unlocked successfully."
BW_SESSION=$(cat /tmp/bw_session_unlocked)

# Export the vault with password protection
bw export --format encrypted_json --raw 1> "$HOME/vaultwarden/exports/vaultwarden-backup.json" --password $EXPORT_PASSWORD --session $BW_SESSION
if [ $? -ne 0 ]; then
  echo "[$(date)] Error: Failed to export Bitwarden vault."
  exit 1
fi
echo "[$(date)] Vault exported successfully to $HOME/vaultwarden/exports/vaultwarden-backup.json."

# Logout from Bitwarden
bw logout --session $BW_SESSION
if [ $? -ne 0 ]; then
  echo "[$(date)] Error: Failed to log out from Bitwarden."
  exit 1
fi
echo "[$(date)] Successfully logged out from Bitwarden."

# Cleanup
rm /tmp/bw_session /tmp/bw_session_unlocked
echo "[$(date)] Cleanup completed."

echo "Backup process finished successfully."
            