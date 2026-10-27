#!/bin/zsh
# Usage: sudo route-watchdog.zsh <app_pid>

APP_PID=$1
[[ $APP_PID =~ '^[0-9]+$' ]] || { echo "Некорректный PID" >&2; exit 1 }

while kill -0 "$APP_PID" 2>/dev/null; do
  sleep 1
done

/usr/local/libexec/routerapp/route-reset.zsh
