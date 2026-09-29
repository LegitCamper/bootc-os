#!/usr/bin/env bash
set -euo pipefail

config="${1:-system-files/etc/dnscrypt-proxy/dnscrypt-proxy.toml}"
expected_host="dns.sawyer.services"
expected_path="/dns-query"

stamp="$(sed -n "s/^[[:space:]]*stamp = '\([^']*\)'.*/\1/p" "$config")"
[[ -n "$stamp" ]] || { echo "No DNS stamp found in $config" >&2; exit 1; }

# resolved forwards to whatever dnscrypt-proxy binds. If they disagree, or a
# value is anything but a real loopback literal, every lookup fails at boot.
listen="$(sed -n "s/^listen_addresses = \['\([^']*\)'\].*/\1/p" "$config")"
resolved_conf="$(dirname "$config")/../systemd/resolved.conf.d/10-dnscrypt.conf"
[[ -f $resolved_conf ]] || resolved_conf=system-files/etc/systemd/resolved.conf.d/10-dnscrypt.conf
upstream="$(sed -n 's/^DNS=//p' "$resolved_conf")"

[[ $listen == "127.0.0.1:53" ]] || { echo "listen_addresses is '$listen', want 127.0.0.1:53" >&2; exit 1; }
[[ $upstream == "127.0.0.1" ]]  || { echo "resolved DNS= is '$upstream', want 127.0.0.1" >&2; exit 1; }
echo "OK: resolved $upstream -> dnscrypt-proxy $listen"

python3 - "$stamp" "$expected_host" "$expected_path" <<'PY'
import base64
import struct
import sys

stamp, expected_host, expected_path = sys.argv[1:]
assert stamp.startswith("sdns://"), "not a DNS stamp"
encoded = stamp.removeprefix("sdns://")
raw = base64.urlsafe_b64decode(encoded + "=" * (-len(encoded) % 4))

assert raw[0] == 0x02, f"expected DoH stamp (0x02), got {raw[0]:#x}"
pos = 1
properties = struct.unpack_from("<Q", raw, pos)[0]
pos += 8

def lp():
    global pos
    length = raw[pos]
    pos += 1
    value = raw[pos:pos + length]
    pos += length
    return value

address = lp()
while True:  # variable-length certificate hash list
    length = raw[pos]
    pos += 1
    more = length & 0x80
    pos += length & 0x7f
    if not more:
        break
host = lp().decode()
path = lp().decode()

assert pos == len(raw), "trailing data in DNS stamp"
assert not address, "stamp hardcodes an address; fly.dev addresses can rotate"
assert host == expected_host, (host, expected_host)
assert path == expected_path, (path, expected_path)
print(f"OK: DoH stamp -> https://{host}{path} (properties={properties:#x})")
PY

# When run in the built image, validate all dnscrypt-proxy options too.
if command -v dnscrypt-proxy >/dev/null; then
  dnscrypt-proxy -config "$config" -check
fi
