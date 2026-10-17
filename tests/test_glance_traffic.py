"""Run: python3 -B -m unittest discover -s tests -p 'test_glance_traffic.py' -v"""
import importlib.util
import json
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch


def load(name, filename):
    spec = importlib.util.spec_from_file_location(name, Path(__file__).resolve().parents[1] / "modules/services" / filename)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


traffic = load("traffic", "glance-traffic.py")
wireguard = load("wireguard_stats", "glance-wireguard.py")
NOW = 1_900_000_000
SERVICES = {"jelly": {"name": "Jellyfin", "ports": [8096], "hosts": ["jelly.frodo.local"]},
            "ssh": {"name": "SSH", "ports": [22], "hosts": []}}
CANARY = "PRIVATE_CREDENTIAL_OR_URL_MUST_NOT_LEAK"


class Traffic(unittest.TestCase):
    def test_tcp_filters_outgoing_internal_unknown_and_handles_ipv6(self):
        lines = "\n".join([
            "0 0 192.168.1.64:8096 192.168.1.116:45000",
            "0 0 [::ffff:192.168.1.64]:22 [::ffff:10.100.0.2]:45678",
            "0 0 127.0.0.1:8096 127.0.0.1:45000",
            "0 0 192.168.1.64:45678 8.8.8.8:443", "broken",
        ])
        with patch.object(traffic.subprocess, "run", return_value=subprocess.CompletedProcess([], 0, lines)) as run:
            counts = traffic.collect_tcp("ss", SERVICES)
        self.assertEqual(dict(counts), {("jelly", "192.168.1.116"): 1, ("ssh", "10.100.0.2"): 1})
        self.assertEqual(run.call_args.args[0], ["ss", "-Htn", "state", "established"])
        self.assertNotIn("shell", run.call_args.kwargs)

    def test_http_window_source_validation_and_no_private_fields(self):
        with tempfile.TemporaryDirectory() as folder:
            def row(ip="192.168.1.116", stamp=NOW, host="jelly.frodo.local", status=200):
                return {"ts": stamp, "status": status, "request": {"remote_ip": ip, "host": host,
                        "headers": {"Authorization": CANARY, "X-Forwarded-For": "8.8.8.8"}, "uri": CANARY}, "resp_headers": {"Set-Cookie": CANARY}}
            entries = [row(), row(status=401), row("10.100.0.2"), row("127.0.0.1"), row(host="unknown"),
                       row(stamp=NOW - 90000), row(stamp=NOW + 99), row(ip=CANARY)]
            Path(folder, "access.json").write_text("\n".join(json.dumps(item) for item in entries))
            counts, errors, last, warnings = traffic.collect_http(folder, SERVICES, NOW)
            self.assertEqual(dict(counts), {("jelly", "192.168.1.116"): 2, ("jelly", "10.100.0.2"): 1})
            self.assertEqual(errors["jelly"], 1)
            self.assertEqual(last["jelly"], NOW)
            self.assertNotIn(CANARY, json.dumps([list(counts.items()), errors, last, warnings]))
            self.assertNotIn(("jelly", "8.8.8.8"), counts)

    def test_snapshot_schema_sources_and_absent_vpn(self):
        with tempfile.TemporaryDirectory() as folder, patch.object(traffic, "collect_tcp", return_value={ ("ssh", "10.100.0.2"): 2 }):
            data = traffic.collect({"services": SERVICES}, "ss", folder, str(Path(folder, "missing")), NOW)
            self.assertEqual(data["sources"], [{"service": "SSH", "ip": "10.100.0.2", "network": "WireGuard", "requests": 0, "tcp": 2}])
            self.assertTrue(any("WireGuard" in warning for warning in data["warnings"]))
            self.assertEqual(data["vpn"], [])

    def test_vpn_whitelist_and_staleness(self):
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder, "peers.json")
            data = {"error": False, "collected_at": NOW, "peers": [{"peer": "abcdef123456", "endpoint_ip": "8.8.8.8",
                    "handshake": NOW - 10, "rx_bytes": 123, "tx_bytes": 456, "extra": CANARY}]}
            path.write_text(json.dumps(data))
            peers, warnings = traffic.load_vpn(path, NOW)
            self.assertFalse(warnings)
            self.assertTrue(peers[0]["recent"])
            self.assertNotIn(CANARY, json.dumps(peers))
            self.assertEqual(traffic.load_vpn(path, NOW + 180)[0], [])

    def test_atomic_snapshot_permissions_and_failure_replaces_old_success(self):
        with tempfile.TemporaryDirectory() as folder:
            output = Path(folder, "statistics.json")
            traffic.write_snapshot(output, {"error": False})
            config = Path(folder, "inventory.json")
            config.write_text(json.dumps({"services": SERVICES}))
            with patch.object(traffic.sys, "argv", ["collector", str(config), "ss", folder, "missing", str(output)]), patch.object(traffic, "collect", side_effect=subprocess.TimeoutExpired("ss", 5)):
                self.assertEqual(traffic.main(), 1)
            self.assertTrue(json.loads(output.read_text())["error"])
            self.assertEqual(output.stat().st_mode & 0o777, 0o644)

    def test_wireguard_only_requests_nonsecret_fields(self):
        key = "test-public-key-not-a-private-key"
        replies = [f"{key}\t[2001:4860:4860::8888]:51820\n", f"{key}\t{NOW}\n", f"{key}\t123\t456\n"]
        with patch.object(wireguard.subprocess, "run", side_effect=[subprocess.CompletedProcess([], 0, value) for value in replies]) as run:
            data = wireguard.collect("wg", "wg0")
        self.assertEqual([call.args[0] for call in run.call_args_list], [["wg", "show", "wg0", field] for field in ("endpoints", "latest-handshakes", "transfer")])
        self.assertNotIn(key, json.dumps(data))
        self.assertEqual(data["peers"][0]["rx_bytes"], 123)
        self.assertEqual(data["peers"][0]["endpoint_ip"], "2001:4860:4860::8888")


if __name__ == "__main__":
    unittest.main()
