#!/bin/zsh
# Usage: sudo install.sh <username>
# Launches from app by AppleScript "with administrator privileges".

set -e

USER_NAME=$1
[[ $EUID -eq 0 ]] || { echo "Root rights is needed" >&2; exit 1 }
[[ $USER_NAME =~ '^[A-Za-z_][A-Za-z0-9._-]*$' ]] || { echo "Uncorrect username" >&2; exit 1 }

SRC=${0:h}
DST=/usr/local/libexec/routerapp
SCRIPTS=(route-blacklist.zsh route-whitelist.zsh route-reset.zsh route-watchdog.zsh)

mkdir -p "$DST" /etc/sudoers.d
chown root:wheel "$DST"
chmod 755 "$DST"

for s in $SCRIPTS; do
  [[ -f $SRC/$s ]] || { echo "No file: $SRC/$s" >&2; exit 1 }
  /usr/bin/install -o root -g wheel -m 755 "$SRC/$s" "$DST/$s"
done

LINE="$USER_NAME ALL=(root) NOPASSWD:"
first=1
for s in $SCRIPTS; do
  if [[ $first == 1 ]]; then
    LINE="$LINE $DST/$s"
    first=0
  else
    LINE="$LINE, $DST/$s"
  fi
done

TMP=$(mktemp)
echo "$LINE" > "$TMP"
/usr/sbin/visudo -cf "$TMP"
/usr/bin/install -o root -g wheel -m 440 "$TMP" /etc/sudoers.d/routerapp
rm -f "$TMP"

echo "Installed in $DST"
