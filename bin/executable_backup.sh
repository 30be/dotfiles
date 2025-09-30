#!/bin/bash

# Set Borg repository path
export BORG_REPO="/home/lyka/borg-repo"
export BORG_PASSPHRASE="$(cat /home/lyka/.borg_passphrase)"

# Create a new backup archive
echo "Starting Borg backup at $(date)..."
borg create --stats --progress \
  ::"{hostname}-{now}" \
  /home/lyka \
  --exclude '/home/lyka/.cache/*' \
  --exclude '/home/lyka/.local/share/Trash/*' \
  --exclude '/home/lyka/borg-repo/*' \
  --exclude '/home/lyka/trash/*'

backup_exit_code=$?

if [ $backup_exit_code -eq 0 ]; then
  echo "Backup completed successfully."
else
  echo "Backup failed with exit code $backup_exit_code."
fi

# Prune old backups
echo "Pruning old backups..."
borg prune \
  --list \
  --keep-daily=7 \
  --keep-weekly=4 \
  --keep-monthly=6

prune_exit_code=$?

if [ $prune_exit_code -eq 0 ]; then
  echo "Pruning completed successfully."
else
  echo "Pruning failed with exit code $prune_exit_code."
fi

echo "Borg backup and prune finished at $(date)."

exit $((backup_exit_code + prune_exit_code))
