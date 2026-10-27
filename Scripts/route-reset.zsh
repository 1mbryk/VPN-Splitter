#!/bin/zsh
# Usage: sudo route-reset.zsh
 
STATE=/var/run/routerapp.routes
 
[[ $EUID -eq 0 ]] || { echo "Root rights needed" >&2; exit 1 }
 
if [[ ! -f $STATE ]]; then
  echo "Nothing to delete"
  exit 0
fi
 
count=0
while read -r kind target; do
  case $kind in
    host) /sbin/route -n delete -host "$target" >/dev/null 2>&1 && (( count++ )) ;;
    net)  /sbin/route -n delete -net "$target" >/dev/null 2>&1 && (( count++ )) ;;
  esac
done < "$STATE"
 
rm -f "$STATE"
echo "Reset: routes deleted: $count"
