#!/bin/bash

result=$(notify-send "Shutdown in 3 minutes. Fill missing timewarrior pieces!" --action="now"="Do it now!" --action="delay"="Delay" -a sleeptime -u critical -e -t 200000)

if [ "$result" == "delay" ]; then
  echo "i am weak." >>/tmp/shutdown_reason.txt
  nvim /tmp/shutdown_reason.txt
  if [ -s "/tmp/shutdown_reason.txt" ]; then
    cat /tmp/shutdown_reason.txt >>~/.shutdown_reasons.txt
    echo "" >>~/.shutdown_reasons.txt
  fi
  rm -f /tmp/shutdown_reason.txt
else
  reboot
fi
