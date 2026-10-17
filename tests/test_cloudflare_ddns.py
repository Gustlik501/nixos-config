"""Offline tests of the actual Bash updater; no real IP or API requests."""
import copy
import json
import os
from pathlib import Path
import subprocess
import sys
import shutil
import tempfile
import unittest

SCRIPT = Path(__file__).resolve().parents[1] / "modules/services/cloudflare-ddns.sh"
TOKEN = "dummyTokenForOfflineTestsOnly1234567890"
ZONE_ID = "a" * 32
IP = "93.184.215.14"
NAMES = ["example.com", "vpn.example.com"]


def fake_curl():
    args = sys.argv[2:]
    path = Path(os.environ["DDNS_FAKE_STATE"])
    state = json.loads(path.read_text())
    url = next(arg for arg in args if arg.startswith("https://"))
    request = {"url": url, "method": "GET"}
    status, body = 200, None
    if url in ("https://api.ipify.org", "https://checkip.amazonaws.com"):
        assert "--config" not in args, "Token must not be sent to IP lookup services"
        body = state["ips"][0 if "ipify" in url else 1]
    else:
        assert url.startswith("https://api.cloudflare.com/client/v4/")
        assert all(TOKEN not in arg for arg in args), "Token must not appear in argv"
        config = Path(args[args.index("--config") + 1])
        assert config.read_text() == f'header = "Authorization: Bearer {TOKEN}"\n'
        assert config.stat().st_mode & 0o777 == 0o600
        method = args[args.index("--request") + 1]
        request["method"] = method
        if state.get("forbidden"):
            status, body = 403, {"success": False}
        elif url.endswith("/zones"):
            body = {"success": True, "result": [{"id": ZONE_ID, "name": "example.com", "status": "active"}]}
        elif method == "GET":
            name = next(arg[5:] for arg in args if arg.startswith("name="))
            records = state["records"].get(name, [])
            body = {"success": True, "result": [r for r in records if r["type"] == "A"]}
        elif method == "PATCH":
            patch = json.loads(Path(args[args.index("--data-binary") + 1][1:]).read_text())
            assert set(patch) == {"content"}, "Only the IP may be changed"
            request["patch"] = patch
            record_id = url.rsplit("/", 1)[1]
            record = next(r for rows in state["records"].values() for r in rows if r["id"] == record_id)
            record.update(patch)
            body = {"success": True, "result": copy.deepcopy(record)}
        else:
            raise AssertionError(f"Unexpected method {method}")
    state["requests"].append(request)
    path.write_text(json.dumps(state))
    if "--output" in args:
        Path(args[args.index("--output") + 1]).write_text(json.dumps(body))
        print(status, end="")
    else:
        print(body)


class DDNS(unittest.TestCase):
    def setUp(self):
        self.assertIsNotNone(shutil.which("jq"), "Run through tests/cloudflare-ddns.nix to supply jq")
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.bin = self.root / "bin"
        self.bin.mkdir()
        shim = self.bin / "curl"
        shim.write_text(f'#!/bin/sh\nexec "{sys.executable}" "{Path(__file__).resolve()}" --fake-curl "$@"\n')
        shim.chmod(0o755)
        self.credentials = self.root / "credentials"
        self.credentials.mkdir()
        self.token = self.credentials / "token"
        self.token.write_text(TOKEN)
        self.token.chmod(0o400)
        self.state_path = self.root / "state.json"
        self.state = {
            "ips": [IP, IP], "requests": [],
            "records": {name: [{
                "id": str(index + 1) * 32, "name": name, "type": "A",
                "content": "8.8.8.8", "proxied": index == 0, "ttl": 1 if index == 0 else 300,
                "comment": "preserve me", "tags": ["owner:test"],
            }] for index, name in enumerate(NAMES)},
        }

    def run_updater(self):
        self.state_path.write_text(json.dumps(self.state))
        result = subprocess.run(["bash", str(SCRIPT)], text=True, capture_output=True, env={
            **os.environ,
            "PATH": str(self.bin) + os.pathsep + os.environ["PATH"],
            "CREDENTIALS_DIRECTORY": str(self.credentials),
            "CF_DDNS_ZONE": "example.com", "CF_DDNS_RECORDS": json.dumps(NAMES),
            "DDNS_FAKE_STATE": str(self.state_path),
        })
        self.state = json.loads(self.state_path.read_text())
        self.assertNotIn(TOKEN, result.stdout + result.stderr + self.state_path.read_text())
        return result

    def patches(self):
        return [r for r in self.state["requests"] if r["method"] == "PATCH"]

    def test_updates_both_ips_preserving_every_other_field(self):
        before = copy.deepcopy(self.state["records"])
        result = self.run_updater()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(len(self.patches()), 2)
        for name in NAMES:
            before[name][0]["content"] = IP
        self.assertEqual(self.state["records"], before)
        self.assertEqual(list(self.root.glob("auth*")), [])

    def test_unchanged_ip_does_not_write(self):
        for rows in self.state["records"].values():
            rows[0]["content"] = IP
        result = self.run_updater()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.patches(), [])
        self.assertEqual(result.stdout, "")

    def test_disagreement_does_not_contact_cloudflare(self):
        self.state["ips"][1] = "8.8.8.8"
        self.assertNotEqual(self.run_updater().returncode, 0)
        self.assertTrue(all("api.cloudflare.com" not in r["url"] for r in self.state["requests"]))

    def test_bad_addresses_fail_closed(self):
        for ip in ["192.168.1.64", "100.64.0.2", "127.0.0.1", "::1", "garbage", "224.0.0.1", "203.0.113.1"]:
            with self.subTest(ip=ip):
                self.state["ips"] = [ip, ip]
                self.assertNotEqual(self.run_updater().returncode, 0)
                self.assertEqual(self.patches(), [])

    def test_missing_record_prevents_all_updates(self):
        self.state["records"][NAMES[1]] = []
        self.assertNotEqual(self.run_updater().returncode, 0)
        self.assertEqual(self.patches(), [])
        self.assertEqual(self.state["records"][NAMES[0]][0]["content"], "8.8.8.8")

    def test_cname_is_not_overwritten_or_recreated(self):
        self.state["records"][NAMES[1]][0]["type"] = "CNAME"
        self.assertNotEqual(self.run_updater().returncode, 0)
        self.assertEqual(self.patches(), [])

    def test_duplicate_records_prevent_all_updates(self):
        self.state["records"][NAMES[1]] *= 2
        self.assertNotEqual(self.run_updater().returncode, 0)
        self.assertEqual(self.patches(), [])

    def test_bad_token_is_not_sent(self):
        self.token.chmod(0o600)
        self.token.write_text('bad-token\nheader = "evil"')
        self.assertNotEqual(self.run_updater().returncode, 0)
        self.assertEqual(self.state["requests"], [])

    def test_api_denial_does_not_write(self):
        self.state["forbidden"] = True
        self.assertNotEqual(self.run_updater().returncode, 0)
        self.assertEqual(self.patches(), [])


if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "--fake-curl":
        fake_curl()
    else:
        unittest.main()
