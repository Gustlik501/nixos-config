"""Read-only systemd inventory for Glance; no Docker socket or service control."""

import datetime
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile


def collect(systemctl, monitored):
    result = subprocess.run(
        [systemctl, "list-units", "--all", "--type=service,timer", "--output=json", "--no-pager"],
        check=True, capture_output=True, text=True, timeout=10,
        env={**os.environ, "LC_ALL": "C", "SYSTEMD_COLORS": "0"},
    )
    units = json.loads(result.stdout)
    if not isinstance(units, list):
        raise ValueError("Expected a systemd unit list")

    services = {}
    infrastructure = []
    timers = []
    for unit in units:
        name = unit["unit"]
        # Explicitly select public status fields. Never export process arguments,
        # environment, journal messages, credentials, or arbitrary unit properties.
        row = {
            "unit": name,
            "name": monitored.get(name, name),
            "load": unit["load"],
            "active": unit["active"],
            "sub": unit["sub"],
        }
        if name in monitored:
            services[name] = row
        elif unit["active"] != "inactive":
            if name.endswith(".timer"):
                timers.append(row)
            elif name.endswith(".service"):
                infrastructure.append(row)

    for name, label in monitored.items():
        if name not in services:
            services[name] = {
                "unit": name, "name": label, "load": "not-found",
                "active": "unknown", "sub": "not-loaded",
            }
    sort_key = lambda row: (row["active"] == "active", row["name"].casefold())
    return {
        "error": False,
        "services": sorted(services.values(), key=sort_key),
        "infrastructure": sorted(infrastructure, key=sort_key),
        "timers": sorted(timers, key=sort_key),
    }


def write_snapshot(output, snapshot):
    snapshot = {
        **snapshot,
        "updated_at": datetime.datetime.now(datetime.timezone.utc).isoformat(),
    }
    output = Path(output)
    # Publish atomically so Glance cannot read a partially written JSON file.
    temporary = None
    try:
        with tempfile.NamedTemporaryFile(mode="w", dir=output.parent, delete=False) as handle:
            temporary = handle.name
            json.dump(snapshot, handle)
            handle.write("\n")
            os.fchmod(handle.fileno(), 0o644)
        os.replace(temporary, output)
    finally:
        if temporary and os.path.exists(temporary):
            os.unlink(temporary)


def main():
    systemctl, monitored_file, output = sys.argv[1:]
    try:
        monitored = json.loads(Path(monitored_file).read_text())
        snapshot = collect(systemctl, monitored)
    except (OSError, ValueError, KeyError, TypeError, subprocess.SubprocessError):
        # Never leave yesterday's green state looking current after a failure.
        snapshot = {"error": True, "services": [], "infrastructure": [], "timers": []}
        print("Could not collect systemd status", file=sys.stderr)
    write_snapshot(output, snapshot)
    return int(snapshot["error"])


if __name__ == "__main__":
    sys.exit(main())
