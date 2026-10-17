# Installed with a Nix-provided Bash/curl/jq/Python environment. No token in argv.
set -euo pipefail
umask 077

fail() { printf 'Cloudflare DDNS: %s\n' "$1" >&2; exit 1; }
: "${CREDENTIALS_DIRECTORY:?Run through cloudflare-ddns.service}"
: "${CF_DDNS_ZONE:?Missing zone name}"
: "${CF_DDNS_RECORDS:?Missing record list}"
[[ "$CF_DDNS_ZONE" =~ ^[a-z0-9][a-z0-9.-]+[a-z0-9]$ ]] || fail 'Invalid zone name.'
jq -e --arg zone "$CF_DDNS_ZONE" '
  type == "array" and length > 0 and all(.[];
    type == "string" and test("^[a-z0-9][a-z0-9.-]+[a-z0-9]$") and
    (. == $zone or endswith("." + $zone)))
' <<< "$CF_DDNS_RECORDS" >/dev/null || fail 'Invalid record allowlist.'
mapfile -t records < <(jq -r 'unique[]' <<< "$CF_DDNS_RECORDS")

token=$(< "$CREDENTIALS_DIRECTORY/token")
[[ "$token" =~ ^[a-zA-Z0-9_-]{20,256}$ ]] || fail 'Token is absent or malformed; provision the SOPS secret.'
work=$(mktemp -d)
trap 'rm -rf -- "$work"' EXIT
printf 'header = "Authorization: Bearer %s"\n' "$token" > "$work/auth.conf"
unset token

# Fail closed if independent IPv4 services disagree or return an invalid address.
public_ip() {
  curl --ipv4 --fail --silent --show-error --proto '=https' --connect-timeout 5 --max-time 12 --retry 2 "$1"
}
ip=$(public_ip https://api.ipify.org) || fail 'Could not determine public IPv4.'
other=$(public_ip https://checkip.amazonaws.com) || fail 'Could not confirm public IPv4.'
[[ "$ip" == "$other" ]] || fail 'Public IPv4 sources disagree; no records changed.'
python3 - "$ip" <<'PY' || fail 'Invalid/non-public IPv4; no records changed.'
import ipaddress, sys
address = ipaddress.IPv4Address(sys.argv[1])
assert address.is_global and not address.is_multicast and not address.is_reserved
PY

api='https://api.cloudflare.com/client/v4'
request() {
  local output="$1" method="$2" url="$3" status
  shift 3
  if ! status=$(curl --config "$work/auth.conf" --ipv4 --silent --show-error --proto '=https' \
      --connect-timeout 5 --max-time 15 --retry 2 --request "$method" \
      --output "$output" --write-out '%{http_code}' "$url" "$@"); then
    fail 'API transport failed; check connectivity/token permissions.'
  fi
  [[ "$status" == 2?? ]] || fail "API returned HTTP $status; check token permissions."
  jq -e '.success == true' "$output" >/dev/null || fail 'API rejected the request.'
}

request "$work/zone.json" GET "$api/zones" --get --data-urlencode "name=$CF_DDNS_ZONE" --data-urlencode 'status=active'
jq -e --arg name "$CF_DDNS_ZONE" '.result | length == 1 and .[0].name == $name and .[0].status == "active"' "$work/zone.json" >/dev/null \
  || fail 'Expected exactly one active matching zone.'
zone_id=$(jq -r '.result[0].id' "$work/zone.json")
[[ "$zone_id" =~ ^[a-fA-F0-9]{32}$ ]] || fail 'Invalid zone ID returned.'

# Preflight the entire allowlist before changing anything. Never create records,
# overwrite CNAMEs, or adjust orange/grey cloud, TTL, comments or tags.
for index in "${!records[@]}"; do
  name="${records[$index]}"
  request "$work/record-$index.json" GET "$api/zones/$zone_id/dns_records" \
    --get --data-urlencode 'type=A' --data-urlencode "name=$name"
  jq -e --arg name "$name" '.result | length == 1 and .[0].name == $name and .[0].type == "A"' "$work/record-$index.json" >/dev/null \
    || fail "Expected exactly one existing A record for $name; no updates attempted."
  id=$(jq -r '.result[0].id' "$work/record-$index.json")
  [[ "$id" =~ ^[a-fA-F0-9]{32}$ ]] || fail 'Invalid record ID returned.'
done
jq -n --arg ip "$ip" '{content: $ip}' > "$work/patch.json"
for index in "${!records[@]}"; do
  name="${records[$index]}"
  previous="$work/record-$index.json"
  if [[ $(jq -r '.result[0].content' "$previous") == "$ip" ]]; then
    continue
  fi
  id=$(jq -r '.result[0].id' "$previous")
  request "$work/updated.json" PATCH "$api/zones/$zone_id/dns_records/$id" \
    --header 'Content-Type: application/json' --data-binary "@$work/patch.json"
  jq -e --arg ip "$ip" --slurpfile old "$previous" '
    .result as $new | $old[0].result[0] as $old |
    $new.content == $ip and $new.id == $old.id and $new.name == $old.name and
    $new.type == $old.type and $new.proxied == $old.proxied and $new.ttl == $old.ttl
  ' "$work/updated.json" >/dev/null || fail "Unexpected update response for $name; inspect the record."
  printf 'Cloudflare DDNS: updated %s to %s (proxy/TTL preserved).\n' "$name" "$ip"
done
