#/bin/bash

cd /home/lyka/OBSIDIAN
git add -A && git commit -m "Hourly auto-commit $(date +%%Y-%%m-%%d_%%H:%%M)" && git push
cd /home/lyka/books
git add -A && git commit -m "Hourly auto-commit $(date +%%Y-%%m-%%d_%%H:%%M)" && git push
cd /home/lyka/.task
git add -A && git commit -m "Hourly auto-commit $(date +%%Y-%%m-%%d_%%H:%%M)" && git push
