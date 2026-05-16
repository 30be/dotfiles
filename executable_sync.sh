#!/bin/bash

cd /home/lyka/d
git add -A; git commit -m "Hourly auto-commit $(date +%Y-%m-%d_%H:%M)"; git pull --rebase; git push
if ! gpg --batch --quiet --decrypt /home/lyka/.password-store/env.gpg 2>/dev/null | diff -q - /home/lyka/.env >/dev/null 2>&1; then
  gpg --batch --yes --trust-model always --encrypt --recipient 042F2E611F54049F --output /home/lyka/.password-store/env.gpg /home/lyka/.env
fi
cd /home/lyka/.password-store
git add -A; git commit -m "Hourly auto-commit $(date +%Y-%m-%d_%H:%M)"; git pull --rebase; git push

cd /home/lyka/.local/share/chezmoi
chezmoi re-add
git add -A; git commit -m "Hourly auto-commit $(date +%Y-%m-%d_%H:%M)"; git pull --rebase; git push

cd /home/lyka/dev/30be.github.io/
cp /home/lyka/heatmap.json static/
cabal run . build
git add -A; git commit -m "Hourly auto-commit $(date +%Y-%m-%d_%H:%M)"; git pull --rebase; git push
