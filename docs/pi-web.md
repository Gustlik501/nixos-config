# Private Pi Web fleet

## Layout and trust

All three hosts use the package pinned in `pkgs/pi-web.nix` (currently
`1.202610.1`, bundled Pi SDK `1.0.0`). The separately installed Pi CLI is managed
by the `llm-agents` input. Updating that input alone does **not** update Pi Web or
its bundled SDK. The two runtimes share the Pi profile layout but not their code.

| Host | Runtime user | Pi profile | Pi Web state |
| --- | --- | --- | --- |
| Frodo | `pi-web` | `/data/pi-web/.pi/agent` | `/data/pi-web/data` |
| Desktop/laptop | `gustl` | `/home/gustl/.pi/agent` | `/var/lib/pi-web-gustl/data` |

The service pair is `pi-web.service` (browser/API) and
`pi-web-sessiond.service` (persistent agent/terminal ownership). Both bind locally:
HTTP on `127.0.0.1:8504`, sessiond on its private state-directory Unix socket.
There are no new agent ports in the firewall and no Docker socket access.
Directory preparation and services require the state filesystem to be mounted.
The state path must have root-owned parents without group/other write access;
initial setup fails closed otherwise. Frodo explicitly normalizes only the mounted
`/data` root to `root:root`, mode `0755`, before setup; legacy dataset ownership
otherwise blocks startup. This changes who can create directories directly under
`/data`, but does not change existing child directories, files, or their owners.
Root provisions only the top-level state path, while child directories are created
as the runtime user, avoiding privileged chown/chmod on agent-controlled symlinks.
On workstations the daemon starts after Home Manager has configured Pi.

Frodo serves `https://pi.frodo.local` through its existing Caddy instance:

```
LAN/VPN browser -> Caddy HTTPS + source-IP check
               -> loopback password gate (8506)
               -> loopback Pi Web (8504)
               -> private sessiond Unix socket
```

Only the configured LAN (`192.168.1.0/24`), WireGuard subnet (`10.100.0.0/24`),
and localhost are accepted. There are no public DNS/router changes. The existing
AdGuard wildcard rewrite covers this hostname **when the client uses AdGuard**;
`.local` resolution on other clients can conflict with mDNS. Caddy's internal CA
must be trusted by the browser; do not routinely bypass certificate warnings.
WireGuard's current generated client profiles use `1.1.1.1` for DNS, so VPN clients
need the home DNS resolver or a deliberate hostname mapping to resolve this URL.

The extra password gate protects the entire application, APIs and WebSockets.
Foreign browser Origins are rejected. Missing/malformed password provisioning
never enables anonymous access; before provisioning, the HTTPS endpoint returns
an error. The gate binds explicitly to loopback; only the HTTPS front door is
intended for browsers. Caddy's administration API is moved from TCP port 2019 to
`/run/caddy/admin.sock`, in a directory accessible only to Caddy/root.

Desktop and laptop initiate SSH reverse tunnels to `192.168.1.64` (Frodo). Frodo
then reaches their Pi Web instances on its own loopback ports 8511 and 8512.
The tunnel pins Frodo's Ed25519 host key, captured from the existing trusted SSH
known-hosts entry. It never uses TOFU/`accept-new` or disables host verification.
Each device reuses its existing SOPS-managed SSH identity. The tunnel reads the
0600, `gustl`-owned key from `/run/secrets/ssh_user_ed25519_key`, the canonical
SOPS runtime path, so `ProtectHome` stays enabled. No private keys enter the store.
Frodo authorizes the existing repository public keys through standard NixOS
`users.users.<account>.openssh.authorizedKeys.keyFiles`:

| Device | Frodo SSH account | Frodo loopback port | Declared public key |
| --- | --- | --- | --- |
| Desktop | `pi-web-desktop` | 8511 | `ssh/desktop.pub` |
| Laptop | `pi-web-laptop` | 8512 | `ssh/laptop.pub` |

SSH reads only `/etc/ssh/authorized_keys.d/%u` for these restricted accounts.
The device keys also retain their already-declared normal SSH access as `gustl`;
reusing a key does not make that key itself tunnel-only. Pi Web's tunnel uses the
restricted account, not `gustl`.

These accounts cannot open shell/SFTP sessions, forward agents, create local
forwards or use arbitrary reverse-forward ports. The listener cannot bind to the
LAN. The laptop needs a route home (e.g. WireGuard) when it is away; this setup
makes no changes to WireGuard. A sleeping/offline device cannot host accessible
sessions. Frodo seeds the two machine-selector entries, preserving other entries;
Nix owns IDs `desktop` and `laptop` and restores their URLs on web-server start.

**Authority:** browser login gives agent/terminal access as `gustl` on workstations
and `pi-web` on Frodo. This is not a read-only chat UI or a security sandbox. The
Frodo user has no sudo, Docker group, or Nix trusted-user permission and filesystem
writes are restricted to `/data/pi-web` plus private temporary space. Workstation
services can edit the user's projects/home, but `NoNewPrivileges` prevents sudo
privilege elevation from their child processes. Pi extensions and server plugins
are trusted code. Do not add untrusted machines or packages to this fleet.

## One-time setup after deployment

Nothing here installs secrets through Nix's world-readable store. Deploy each
host yourself with the existing rebuild helpers. Hermes' module, upstream input,
package/service configuration, and env secret have been removed. Its old
`/data/hermes` files are left untouched; uninstalling is not data erasure.

### 1. Browser password on Frodo

```sh
ssh -t gustl@frodo.local 'sudo pi-web-password'
ssh -t gustl@frodo.local 'sudo systemctl restart pi-web-auth.service'
```

Choose a unique password of at least 16 characters (bcrypt supports up to 72
bytes). The helper prompts twice, stores only its bcrypt hash in
`/var/lib/pi-web-gateway/password.hash` as root, mode 0600, and **does not restart
services**. Username: `gustl`. A restart applies password changes to the gate.
For encrypted declarative provisioning later, set
`services.pi-web.gateway.passwordHashFile` to a SOPS-decrypted bcrypt secret
instead; manage that secret through SOPS rather than the password helper.

### 2. Machines connect declaratively

Rebuild Frodo and each workstation. The existing encrypted SSH secrets and public
keys provide enrollment automatically: no `ssh-keygen`, `scp`, manual authorized
key installation, or separate tunnel identity is needed. The tunnel starts at
boot/rebuild and retries network failures. If the SOPS secret is absent, startup
is skipped rather than using another identity. Secret rotation requests a tunnel
restart; with systemd-based SOPS installation the tunnel explicitly waits for it.

When rotating a device key, update its existing encrypted secret and matching
`ssh/<device>.pub`, then deploy both sides. A changed Frodo host key fails closed:
verify the replacement out of band before changing `tunnel.serverPublicKey`.
Old manually generated `/var/lib/pi-web-gustl/tunnel_ed25519` files and
`/var/lib/pi-web-links/*.pub` are no longer used by this fleet; they are not
automatically deleted.

### 3. Projects and model login

Open `https://pi.frodo.local`, sign in, and use the machine selector. Add the
project folders you want; default workspaces are `/data/pi-web/workspace` on
Frodo and `/var/lib/pi-web-gustl/workspace` on workstations. Frodo needs a fresh
provider login in the browser. Select **Local/Frodo**, press **Ctrl+K** (Cmd+K on
macOS), and choose **Configure Provider Authentication**. Choose **OAuth**, then
**OpenAI Codex (legacy)** (`openai-codex`, matching the configured provider) for
a ChatGPT/Codex subscription, and follow the browser flow.
If the localhost callback cannot reach Frodo, paste the final redirect URL/code
into Pi Web's login dialog when prompted, never into chat or Git. The command
`/login openai-codex` in an existing session opens the same authentication flow.

This stores mutable credentials in `/data/pi-web/.pi/agent/auth.json`, not the
Nix store. OAuth login is an interactive, one-time authorization, not a flake
setting; refresh tokens are managed by Pi. API-key credentials could separately
be supplied with SOPS, but must never be plaintext Nix values. Frodo does not copy
`gustl`'s or retired service credentials. Desktop/laptop reuse their existing Pi
profiles and credentials.

On Frodo, Nix merges the standard theme/provider/model/package keys into writable
settings at daemon start, preserving other preferences and authentication. The
same three store-managed Pi extensions are configured as in the terminal setup,
including `pi-web-access`. On workstations Home Manager retains ownership of those
settings. Pi Web's own config is writable and seeded with its Updates plugin
disabled; do not use imperative installers, `pi-web install`, or self-updaters to
manage this installation. Browser authentication and model-provider login are
separate credentials.

Pi Web manages its own live sessions. Existing standalone terminal `pi` processes
are not automatically attached. Web/API restarts preserve the session daemon;
rebooting or restarting the daemon interrupts active agent work and terminals.

## Updating and restarting

1. Review upstream changes; update `version`, `src.rev`, `src.hash`, and
   `npmDepsHash` in `pkgs/pi-web.nix`. Obtain new fixed-output hashes by temporarily
   setting them to `lib.fakeHash` and building `nix build --no-link .#pi-web`.
2. If upstream still omits lockfile integrity entries, update
   `pkgs/pi-web-integrities.json` with registry-published checksums for the exact
   missing versions and review the patch guard. Never turn off dependency hash
   verification. The current patch supplies seven missing Pi 1.0.0 checksums;
   no dependency versions are rewritten.
3. Run the tests below and build all three host configurations.
4. Deploy the same Pi Web package to every host. Mixed-version federation is not
   supported upstream. Avoid starting work during the rollout.
5. **Once sessions are idle**, on every host explicitly apply the new daemon:

   ```sh
   sudo systemctl restart pi-web.service
   sudo systemctl restart pi-web-sessiond.service
   ```

   Refresh the browser afterwards. Sessiond deliberately does not automatically
   stop/restart on rebuild changes, so an upgrade can temporarily leave old daemon
   code running until this step. A normal reboot also loads the new daemon, but
   likewise interrupts work. The web server restarts normally when changed.

Keep Home Manager and the dedicated Frodo profile's extensions compatible with
both the CLI Pi and Pi Web's pinned SDK. The build retains devDependencies because
upstream places runtime Pi SDK peers there; blindly pruning them breaks sessiond.
Do not treat a successful CLI extension load as proof of full browser compatibility.

```sh
nix build --no-link .#pi-web
nix flake check --no-build --no-write-lock-file
nix eval --offline --impure --json --file tests/pi-web.nix
nix build --impure --no-link --file tests/pi-web-vm.nix
nix build --impure --no-link --file tests/pi.nix
```

The fleet VM test covers native sessiond startup with the configured extensions,
PTY operation, HTTPS login/API/WebSocket gating, wrong-origin/source denial,
private Caddy administration and reloads, automatic reverse forwarding with
declarative public keys and a runtime secret fixture (no manual enrollment),
shell/wrong-port denial, machine proxying, legacy `/data` ownership repair without
changing child data, symlink-safe directory setup, and web restart ownership. It does not
send paid model prompts or use real provider credentials. Verify real model login,
session creation and browser extension features after deployment.

Useful checks:

```sh
systemctl status pi-web pi-web-sessiond
journalctl -u pi-web -u pi-web-sessiond -b
# On workstations:
systemctl status pi-web-tunnel
# On Frodo:
systemctl status pi-web-auth
```
