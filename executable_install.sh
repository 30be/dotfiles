#!/bin/bash
systemctl --user daemon-reload
systemctl --user enable sync.timer
systemctl --user start sync.timer
