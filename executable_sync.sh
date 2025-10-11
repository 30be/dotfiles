#!/bin/bash

# Git operations
cd /home/lyka/Drive/OBSIDIAN
git add -A && git commit -m "Hourly auto-commit $(date +%Y-%m-%d_%H:%M)" && git push
cd /home/lyka/books
git add -A && git commit -m "Hourly auto-commit $(date +%Y-%m-%d_%H:%M)" && git push
cd /home/lyka/.task
git add -A && git commit -m "Hourly auto-commit $(date +%Y-%m-%d_%H:%M)" && git push
cd /home/lyka/drafts
git add -A && git commit -m "Hourly auto-commit $(date +%Y-%m-%d_%H:%M)" && git push

# Update package list
yay -Qqe >/home/lyka/pkglist.txt
chezmoi add /home/lyka/pkglist.txt

# Rsync synchronization
echo "Starting Rsync synchronization to remote at $(date)..."

# Define local and remote Borg repositories
export BORG_LOCAL_REPO="/home/lyka/borg-repo"
export BORG_REMOTE_HOST="root@31.57.54.31"
export BORG_REMOTE_PATH="/root/borg-repo" # IMPORTANT: Adjust /root/borg-repo to your desired path on the remote server

# Synchronize local Borg repository to remote
rsync -avz --delete "$BORG_LOCAL_REPO/" "$BORG_REMOTE_HOST:$BORG_REMOTE_PATH"

sync_exit_code=$?

if [ $sync_exit_code -eq 0 ]; then
  echo "Rsync synchronization completed successfully."
else
  echo "Rsync synchronization failed with exit code $sync_exit_code."
fi

echo "Rsync synchronization finished at $(date)."

/home/lyka/bin/sync_heatmap.sh

exit $sync_exit_code
