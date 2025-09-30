#!/bin/sh
#
# Borg backup script
#

# Source environment variables, like BORG_PASSPHRASE
if [ -f ~/.env ]; then
    . ~/.env
fi

# The repository to backup to
export BORG_REPO=~/borg-repo

# The directory to backup
BACKUP_DIR=~

# Exclude patterns
EXCLUDE="
--exclude ~/.cache
--exclude ~/.local/share/Trash
"

# Create a new backup archive
borg create --stats --progress ::'{hostname}-{now:%Y-%m-%d}' $BACKUP_DIR $EXCLUDE

# Prune old backups
borg prune -v --list --keep-daily=7 --keep-weekly=4 --keep-monthly=6 $BORG_REPO
