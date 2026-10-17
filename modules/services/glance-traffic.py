"""Sanitized, read-only connection/request statistics; no packet or body capture."""
import collections
import datetime
import gzip
import ipaddress
import json
import math
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import time

MAX_LOG_BYTES = 80 * 1024 * 1024
MAX_LINE_BYTES = 64 * 1024


def address(value):
    parsed = ipaddress.ip_address(value)
    return str(parsed.ipv4_mapped if getattr(parsed, "ipv4_mapped", None) else parsed)


def network(value):
    ip = ipaddress.ip_address(value)
    if ip.is_loopback:
        return "Loopback"
    if ip in ipaddress.ip_network("10.100.0.0/24"):
        return "WireGuard"
    if ip in ipaddress.ip_network("192.168.1.0/24") or ip.is_link_local:
        return "LAN"
    if ip.is_private:
        return "Private network"
    return "Public IP"


def endpoint(value):
    host, port = value.rsplit(":", 1)
    if not 0 <= int(port) <= 65535:
        raise ValueError("Invalid port")
    return address(host.strip("[]")), int(port)


def collect_tcp(ss, services):
    result = subprocess.run([ss, "-Htn", "state", "established"], check=True,
                            capture_output=True, text=True, timeout=5)
    ports = {port: key for key, value in services.items() for port in value["ports"]}
    counts = collections.Counter()
    for line in result.stdout.splitlines():
        try:
            fields = line.split()
            local, remote = fields[-2:]
            _, port = endpoint(local)
            ip, _ = endpoint(remote)
            # Ignore internal proxy/database/health-check legs, not actual users.
            if port in ports and network(ip) != "Loopback":
                counts[(ports[port], ip)] += 1
        except (ValueError, IndexError):
            continue
    return counts


def collect_http(directory, services, now):
    hosts = {host: key for key, value in services.items() for host in value["hosts"]}
    counts = collections.Counter()
    errors = collections.Counter()
    last = {}
    warnings = []
    remaining = MAX_LOG_BYTES
    paths = sorted(Path(directory).glob("access*"), key=lambda p: p.stat().st_mtime, reverse=True)
    if not paths:
        warnings.append("No web access logs yet; request history starts after deployment.")
    for path in paths[:8]:
        try:
            opener = gzip.open if path.suffix == ".gz" else open
            with opener(path, "rb") as source:
                while remaining > 0:
                    line = source.readline(MAX_LINE_BYTES + 1)
                    if not line:
                        break
                    remaining -= len(line)
                    if len(line) > MAX_LINE_BYTES:
                        warnings.append("An oversized log entry was skipped.")
                        break
                    try:
                        row = json.loads(line)
                        stamp = float(row["ts"])
                        if not math.isfinite(stamp) or not now - 86400 <= stamp <= now + 5:
                            continue
                        request = row["request"]
                        # Trust only the actual socket peer, never arbitrary XFF.
                        ip = address(request["remote_ip"])
                        host = request["host"].lower().split(":", 1)[0]
                        key = hosts.get(host)
                        status = int(row["status"])
                        if key is None or network(ip) == "Loopback" or not 100 <= status <= 599:
                            continue
                        counts[(key, ip)] += 1
                        errors[key] += int(status >= 400)
                        last[key] = max(stamp, last.get(key, 0))
                    except (ValueError, KeyError, TypeError):
                        warnings.append("A malformed/incomplete log entry was skipped.")
        except OSError:
            warnings.append("An access log could not be read.")
        if remaining <= 0:
            warnings.append("History scan limit reached; request counts may be incomplete.")
            break
    return counts, errors, last, warnings


def load_vpn(path, now):
    try:
        data = json.loads(Path(path).read_text())
        if data.get("error") or abs(now - float(data["collected_at"])) > 120:
            raise ValueError("Unavailable/stale VPN collector")
        # Explicit schema; never publish a caller's arbitrary object/fields.
        peers = []
        for row in data["peers"]:
            identifier = row["peer"]
            if not isinstance(identifier, str) or len(identifier) != 12 or any(c not in "0123456789abcdef" for c in identifier):
                raise ValueError("Invalid peer ID")
            ip = address(row["endpoint_ip"]) if row["endpoint_ip"] else "Not observed"
            stamp = int(row["handshake"])
            rx, tx = int(row["rx_bytes"]), int(row["tx_bytes"])
            if min(stamp, rx, tx) < 0:
                raise ValueError("Invalid counter")
            peers.append({
                "peer": identifier, "endpoint_ip": ip,
                "recent": stamp > 0 and 0 <= now - stamp < 180,
                "handshake_at": datetime.datetime.fromtimestamp(stamp, datetime.timezone.utc).isoformat() if stamp else "",
                "rx_bytes": rx, "tx_bytes": tx,
            })
        return peers, []
    except (OSError, ValueError, KeyError, TypeError, OverflowError):
        return [], ["WireGuard statistics unavailable or stale; check glance-wireguard.service."]


def collect(config, ss, directory, vpn_file, now=None):
    now = time.time() if now is None else now
    warnings = []
    services = config["services"]
    tcp = collect_tcp(ss, services)
    http, errors, last, log_warnings = collect_http(directory, services, now)
    warnings += log_warnings
    peers, vpn_warnings = load_vpn(vpn_file, now)
    warnings += vpn_warnings
    sources = []
    for key, ip in set(tcp) | set(http):
        sources.append({"service": services[key]["name"], "ip": ip,
                        "network": network(ip), "requests": http[(key, ip)], "tcp": tcp[(key, ip)]})
    sources.sort(key=lambda row: (-row["requests"], -row["tcp"], row["service"], row["ip"]))
    rows = []
    for key, value in services.items():
        rows.append({
            "name": value["name"], "web": bool(value["hosts"]),
            "requests": sum(count for (service, _), count in http.items() if service == key),
            "unique_ips": sum(1 for service, _ in http if service == key),
            "errors": errors[key],
            "tcp": sum(count for (service, _), count in tcp.items() if service == key),
            "last_request_at": datetime.datetime.fromtimestamp(last[key], datetime.timezone.utc).isoformat() if key in last else "",
        })
    return {"error": False, "warnings": sorted(set(warnings)), "services": rows,
            "sources": sources[:100], "vpn": peers, "window_hours": 24}


def write_snapshot(path, data, mode=0o644):
    output = Path(path)
    data = {**data, "updated_at": datetime.datetime.now(datetime.timezone.utc).isoformat()}
    name = None
    try:
        with tempfile.NamedTemporaryFile(mode="w", dir=output.parent, delete=False) as target:
            name = target.name
            json.dump(data, target)
            target.write("\n")
            os.fchmod(target.fileno(), mode)
        os.replace(name, output)
    finally:
        if name and os.path.exists(name):
            os.unlink(name)


def main():
    config_file, ss, directory, vpn_file, output = sys.argv[1:]
    try:
        result = collect(json.loads(Path(config_file).read_text()), ss, directory, vpn_file)
    except (OSError, ValueError, TypeError, KeyError, subprocess.SubprocessError):
        result = {"error": True, "warnings": [], "services": [], "sources": [], "vpn": []}
        print("Traffic statistics collection failed; no private data logged", file=sys.stderr)
    write_snapshot(output, result)
    return int(result["error"])


if __name__ == "__main__":
    sys.exit(main())
