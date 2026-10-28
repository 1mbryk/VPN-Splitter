#!/bin/zsh

STATE=/var/run/routerapp.routes
IFACE=$1
GW=$2
LIST=$3
IPV4='^[0-9]{1,3}(\.[0-9]{1,3}){3}$'
umask 077

[[ $EUID -eq 0 ]] || { echo "Root privileges required" >&2; exit 1 }
[[ $IFACE =~ '^utun[0-9]+$' ]] || { echo "Invalid interface: $IFACE" >&2; exit 1 }
[[ $GW =~ $IPV4 ]] || { echo "Invalid gateway address: $GW" >&2; exit 1 }
[[ -r $LIST ]] || { echo "List file not found: $LIST" >&2; exit 1 }
/sbin/ifconfig "$IFACE" >/dev/null 2>&1 || { echo "Interface $IFACE does not exist" >&2; exit 1 }

reset_routes() {
  [[ -f $STATE ]] || return 0
  local kind target
  while read -r kind target; do
    case $kind in
      host) /sbin/route -n delete -host "$target" >/dev/null 2>&1 ;;
      net)  /sbin/route -n delete -net "$target" >/dev/null 2>&1 ;;
    esac
  done < "$STATE"
  rm -f "$STATE"
}

reset_routes

GW_IF=$(/sbin/route -n get "$GW" 2>/dev/null | awk '/interface:/{print $2}')
[[ -n $GW_IF && $GW_IF != $IFACE ]] || {
  echo "Gateway $GW is unreachable or routed via $IFACE (interface: ${GW_IF:-none})" >&2
  exit 1
}

: > "$STATE"

while read -r ip || [[ -n $ip ]]; do
  [[ $ip =~ $IPV4 ]] || continue
  if err=$(/sbin/route -n add -host "$ip" -interface "$IFACE" 2>&1); then
    echo "host $ip" >> "$STATE"
  else
    echo "Warning: host $ip was not added: $err" >&2
  fi
done < "$LIST"

DNS_LIST=$(/usr/sbin/scutil --dns | awk '/nameserver\[[0-9]+\]/{print $3}' | sort -u)
while read -r dns; do
  [[ $dns =~ $IPV4 ]] || continue
  grep -qx "host $dns" "$STATE" && continue
  dns_if=$(/sbin/route -n get "$dns" 2>/dev/null | awk '/interface:/{print $2}')
  [[ $dns_if == $IFACE ]] || continue
  if err=$(/sbin/route -n add -host "$dns" -interface "$IFACE" 2>&1); then
    echo "host $dns" >> "$STATE"
    echo "DNS server $dns kept in the tunnel"
  else
    echo "Warning: DNS server $dns was not added: $err" >&2
  fi
done <<< "$DNS_LIST"

FAILED=0
for net in 0.0.0.0/2 64.0.0.0/2 128.0.0.0/2 192.0.0.0/2; do
  if err=$(/sbin/route -n add -net "$net" "$GW" 2>&1); then
    echo "net $net" >> "$STATE"
  else
    echo "Failed to add $net: $err" >&2
    FAILED=1
  fi
done

if (( FAILED )); then
  echo "Rolling back partially applied routes" >&2
  reset_routes
  exit 1
fi

echo "Whitelist applied: gateway $GW ($GW_IF), entries: $(wc -l < "$STATE" | tr -d ' ')"
