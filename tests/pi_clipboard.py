"""Offline TUI regression: real Pi + configured extensions, synthetic clipboard.

Run from tests/pi.nix. Never reads/replaces the desktop clipboard, copies auth,
submits prompts, or saves sessions. Verify both legacy and Kitty Alt+V input.
"""

import base64
import fcntl
import json
import os
from pathlib import Path
import pty
import select
import struct
import subprocess
import sys
import tempfile
import termios
import time


def main():
    binary = os.environ["PI_TEST_BINARY"]
    source = Path(os.environ["PI_CODING_AGENT_DIR"])
    with tempfile.TemporaryDirectory(prefix="pi-clipboard-test-") as directory:
        root = Path(directory)
        agent = root / "home/.pi/agent"
        agent.mkdir(parents=True)
        (root / "bin").mkdir()
        (root / "tmp").mkdir()
        settings = json.loads((source / "settings.json").read_text())
        settings["quietStartup"] = True
        (agent / "settings.json").write_text(json.dumps(settings))
        (agent / "keybindings.json").write_text((source / "keybindings.json").read_text())
        image = base64.b64decode(
            "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+j7MsAAAAASUVORK5CYII="
        )
        (root / "image.png").write_bytes(image)
        mode = root / "mode"
        mode.write_text("image")
        paste = root / "bin/wl-paste"
        paste.write_text(
            f"#!{sys.executable}\nimport sys\nfrom pathlib import Path\n"
            f"mode = Path({str(mode)!r}).read_text()\n"
            "if '--list-types' in sys.argv:\n"
            "    print('image/png' if mode == 'image' else 'text/plain')\n"
            "elif mode == 'image' and 'image/png' in sys.argv:\n"
            f"    sys.stdout.buffer.write(Path({str(root / 'image.png')!r}).read_bytes())\n"
            "elif mode == 'text':\n"
            "    print('synthetic clipboard text', end='')\n"
            "else:\n"
            "    sys.exit(1)\n"
        )
        paste.chmod(0o755)
        env = {
            **os.environ,
            "HOME": str(root / "home"),
            "PI_CODING_AGENT_DIR": str(agent),
            "TMPDIR": str(root / "tmp"),
            "PI_OFFLINE": "1",
            "WAYLAND_DISPLAY": "pi-synthetic-clipboard",
            "DISPLAY": "",
            "XDG_SESSION_TYPE": "wayland",
            "TERM": "xterm-kitty",
            "PATH": str(root / "bin") + ":" + os.environ["PATH"],
        }
        master, slave = pty.openpty()
        fcntl.ioctl(slave, termios.TIOCSWINSZ, struct.pack("HHHH", 40, 180, 0, 0))
        process = subprocess.Popen(
            [binary, "--offline", "--no-session", "--no-context-files", "--no-approve"],
            stdin=slave, stdout=slave, stderr=slave, cwd=root / "home", env=env,
            start_new_session=True,
        )
        os.close(slave)
        output = bytearray()

        def drain(seconds):
            deadline = time.monotonic() + seconds
            while time.monotonic() < deadline:
                if select.select([master], [], [], min(0.1, deadline - time.monotonic()))[0]:
                    try:
                        output.extend(os.read(master, 65536))
                    except OSError:
                        break

        def wait_for(predicate):
            deadline = time.monotonic() + 15
            while time.monotonic() < deadline:
                drain(0.1)
                if predicate():
                    return
                assert process.poll() is None, "Pi exited during clipboard test"
            raise AssertionError("Clipboard input did not reach Pi's editor")

        try:
            drain(3)
            for count, key in enumerate((b"\x1bv", b"\x1b[118;3u"), start=1):
                os.write(master, key)
                wait_for(lambda: len(list((root / "tmp").glob("pi-clipboard-*.png"))) == count)
                files = list((root / "tmp").glob("pi-clipboard-*.png"))
                assert all(path.read_bytes() == image for path in files)
                wait_for(lambda: any(path.name.encode() in output for path in files))
                print(f"Alt+V ({'legacy' if count == 1 else 'Kitty'}): PNG inserted")
            mode.write_text("text")
            os.write(master, b"\x1bv")
            wait_for(lambda: b"synthetic clipboard text" in output)
            assert len(list((root / "tmp").glob("pi-clipboard-*.png"))) == 2
            assert b"Host-provided extension packages" not in output
            assert b"Failed to paste from clipboard" not in output
            print("Alt+V text fallback: PASS; no prompts submitted")
        except Exception:
            print(output.decode("utf-8", "replace")[-12000:])
            raise
        finally:
            process.terminate()
            try:
                process.wait(timeout=8)
            except subprocess.TimeoutExpired:
                process.kill()
                process.wait()
            os.close(master)


if __name__ == "__main__":
    main()
