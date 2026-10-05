"""Run: python3 -m unittest discover -s tests -p 'test_glance_status.py' -v"""

import importlib.util
import json
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location(
    "glance_status", Path(__file__).resolve().parents[1] / "modules/services/glance-status.py"
)
status = importlib.util.module_from_spec(spec)
spec.loader.exec_module(status)


def unit(name, active="active", sub="running"):
    return {
        "unit": name, "load": "loaded", "active": active, "sub": sub,
        "description": "PRIVATE METADATA MUST NOT BE PUBLISHED",
    }


class GlanceStatusTests(unittest.TestCase):
    def test_inventory_and_stopped_services(self):
        rows = [
            unit("postgresql.service"),
            unit("hermes-agent.service", "inactive", "dead"),
            unit("qbittorrent.service", "inactive", "dead"),
            unit("wg-quick-wg0.service", "active", "exited"),
            unit("sshd.service"),
            unit("unexpected.service", "failed", "failed"),
            unit("boot-job.service", "inactive", "dead"),
            unit("zfs-scrub.timer", "active", "waiting"),
        ]
        monitored = {
            "postgresql.service": "PostgreSQL",
            "hermes-agent.service": "Hermes",
            "qbittorrent.service": "qBittorrent",
            "wg-quick-wg0.service": "WireGuard",
            "missing.service": "Missing service",
        }
        with patch.object(status.subprocess, "run", return_value=subprocess.CompletedProcess([], 0, json.dumps(rows))) as run:
            result = status.collect("/absolute/systemctl", monitored)
        command = run.call_args.args[0]
        self.assertEqual(command[0:2], ["/absolute/systemctl", "list-units"])
        self.assertIn("--type=service,timer", command)
        self.assertEqual(run.call_args.kwargs["timeout"], 10)
        self.assertNotIn("shell", run.call_args.kwargs)
        services = {row["unit"]: row for row in result["services"]}
        self.assertEqual(set(services), set(monitored))
        self.assertEqual(services["hermes-agent.service"]["active"], "inactive")
        self.assertEqual(services["qbittorrent.service"]["active"], "inactive")
        self.assertEqual(services["wg-quick-wg0.service"]["sub"], "exited")
        self.assertEqual(services["missing.service"]["active"], "unknown")
        self.assertEqual({row["unit"] for row in result["infrastructure"]}, {"sshd.service", "unexpected.service"})
        self.assertEqual(result["infrastructure"][0]["active"], "failed")
        self.assertEqual(result["timers"][0]["unit"], "zfs-scrub.timer")
        self.assertNotIn("PRIVATE", json.dumps(result))
        self.assertFalse(result["error"])

    def test_invalid_output_is_not_success(self):
        for output in ["not json", "{}", '[{"unit":"broken.service"}]']:
            with self.subTest(output=output), patch.object(status.subprocess, "run", return_value=subprocess.CompletedProcess([], 0, output)):
                with self.assertRaises((ValueError, KeyError)):
                    status.collect("systemctl", {})

    def test_atomic_snapshot_permissions(self):
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / "status.json"
            status.write_snapshot(output, {"error": False, "services": []})
            self.assertEqual(output.stat().st_mode & 0o777, 0o644)
            self.assertIn("updated_at", json.loads(output.read_text()))
            status.write_snapshot(output, {"error": True})
            self.assertTrue(json.loads(output.read_text())["error"])
            self.assertEqual(list(Path(directory).iterdir()), [output])

    def test_errors_replace_old_success_with_unavailable(self):
        errors = [subprocess.CalledProcessError(1, "systemctl"), subprocess.TimeoutExpired("systemctl", 10), OSError("unavailable")]
        for error in errors:
            with self.subTest(error=error), tempfile.TemporaryDirectory() as directory:
                config = Path(directory) / "monitored.json"
                config.write_text("{}")
                output = Path(directory) / "status.json"
                status.write_snapshot(output, {"error": False, "services": [{"active": "active"}]})
                with patch.object(status.sys, "argv", ["collector", "systemctl", str(config), str(output)]), patch.object(status, "collect", side_effect=error):
                    self.assertEqual(status.main(), 1)
                data = json.loads(output.read_text())
                self.assertTrue(data["error"])
                self.assertEqual(data["services"], [])


if __name__ == "__main__":
    unittest.main()
