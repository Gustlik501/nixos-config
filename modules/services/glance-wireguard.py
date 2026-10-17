"""Privileged kernel reader: query only non-secret WireGuard fields.

Never read wg0.conf, private-key/preshared-keys, dump, showconf, or packet data.
"""
import hashlib
import ipaddress
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import time


def collect(wg, interface):
    tables = {}
    for field in ("endpoints", "latest-handshakes", "transfer"):
        result = subprocess.run([wg, "show", interface, field], check=True,
                                capture_output=True, text=True, timeout=3,
                                env={**os.environ, "WG_HIDE_KEYS": "always"})
        table = {}
        for line in result.stdout.splitlines():
            key, *values = line.split()
            table[key] = values
        tables[field] = table
    peers = []
    for key, values in tables["endpoints"].items():
        endpoint = values[0]
        ip = ""
        if endpoint != "(none)":
            ip = str(ipaddress.ip_address(endpoint.rsplit(":", 1)[0].strip("[]")))
        handshake = int(tables["latest-handshakes"].get(key, ["0"])[0])
        rx, tx = map(int, tables["transfer"].get(key, ["0", "0"]))
        if min(handshake, rx, tx) < 0:
            raise ValueError("Invalid counter")
        peers.append({"peer": hashlib.sha256(key.encode()).hexdigest()[:12],
                      "endpoint_ip": ip, "handshake": handshake,
                      "rx_bytes": rx, "tx_bytes": tx})
    return {"error": False, "collected_at": time.time(), "peers": peers}


def main():
    wg, interface, output = sys.argv[1:]
    try:
        result = collect(wg, interface)
    except (OSError, ValueError, IndexError, subprocess.SubprocessError):
        result = {"error": True, "collected_at": time.time(), "peers": []}
        print("WireGuard statistics unavailable; no private data logged", file=sys.stderr)
    name = None
    path = Path(output)
    try:
        with tempfile.NamedTemporaryFile(mode="w", dir=path.parent, delete=False) as target:
            name = target.name
            json.dump(result, target)
            target.write("\n")
            os.fchmod(target.fileno(), 0o640)
        os.replace(name, path)
    finally:
        if name and os.path.exists(name):
            os.unlink(name)
    # A missing interface must not block the rest of the statistics page.
    return 0


if __name__ == "__main__":
    sys.exit(main())
