#!/bin/bash

rsync -avz --delete --no-o --no-g /home/lyka/heatmap.json root@23.94.5.170:/srv/shoggothstaring.com/ &&
  ssh root@23.94.5.170 "chown caddy:caddy /srv/shoggothstaring.com/heatmap.json" &&
  echo "Sync and ownership fixed." || echo "Sync failed."
