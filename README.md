# nixos-config

Flake-based NixOS configuration for my machines.

## Getting started

1. **Install Nix/NixOS** with the `nix-command` and `flakes` features enabled. On NixOS you can add the following to `/etc/nixos/configuration.nix`:
   
   ```
   nix.settings.experimental-features = ["nix-command" "flakes"];
   ```

2. **Clone this repository**

3. **Apply a host configuration**.
   
   - **Workstations:** Replace `laptop` with the desired host (`laptop` or `desktop`):
     ```
     sudo nixos-rebuild switch --flake .#laptop
     ```
   - **Server (Frodo):** See [hosts/frodo/README.md](hosts/frodo/README.md) for server-specific instructions.

   *Note: This command now automatically applies both system and user (Home Manager) configurations.*

## Helper commands
Run these from the repo root:
- Update all inputs: `nix run .#update`
- Rebuild current host: `nix run .#rebuild-pc`
- Rebuild Frodo via SSH: `nix run .#rebuild-frodo`

## Pi coding agent

`home/pi` is included in the base Home Manager profile (laptop, desktop and
Frodo). It installs Pi from the existing locked `llm-agents` input, plus the
plugins installed on my Windows device:

- `@tian.zuo/pi-usage` **0.2.0**
- `pi-web-access` **0.28.0**
- `@plannotator/pi-extension` **0.27.12** (including its bundled skill)

The plugins and their transitive dependencies are pinned in
`pkgs/pi-plugins/package-lock.json`, fetched with integrity hashes and installed
in the Nix store, without lifecycle scripts or startup npm installs. Node.js 24,
Git, ripgrep, fd, xdg-utils, yt-dlp and FFmpeg are available for plugin features.
Pi itself follows `flake.lock` (currently **0.84.4**, versus **0.85.1** on Windows).
Standalone skills in `~/.agents/skills` are not part of these three npm plugins
and are not copied by this module.

After rebuilding, run `pi` and use `/login` to authenticate. No credentials,
provider keys, sessions, trust decisions or Windows-specific paths are committed.
Web search can reuse the Codex login; other providers need their own local setup.
Browser-based plugin UIs on headless Frodo require SSH forwarding and local
browser access as described in each plugin's documentation.

Home activation merges the declared dark theme, OpenAI Codex provider,
`gpt-6-astra` model and plugin paths into `~/.pi/agent/settings.json`. The file
stays writable for Pi; other settings are preserved. Those four declared keys
are reset on each activation, so change them in `home/pi/default.nix`, not with
`pi install` or `pi update`. Authentication and sessions remain user-managed.
If the default model is unavailable to your account, select another with `/model`
and update the declared default to make it persistent across rebuilds.

To update plugins, edit the exact versions in `pkgs/pi-plugins/package.json`, then:

```sh
cd pkgs/pi-plugins
npm install --package-lock-only --ignore-scripts --legacy-peer-deps --no-audit --no-fund
```

Commit both JSON files and rebuild. To update Pi, update the `llm-agents` flake
input rather than using Pi's self-updater.

Validate the plugin build and settings activation (creation, preservation,
idempotence and invalid-JSON handling) without rebuilding a host:

```sh
nix build --impure --no-link --file tests/pi.nix
```

## Secrets (sops-nix)
- `sops-nix` is wired into all hosts through `flake.nix`.
- Secret files live under `secrets/`.
- Default per-host secrets file: `secrets/<host>/secrets.yaml`.
- Bootstrap and key-management notes are in `secrets/README.md`.
- SSH user private keys are declared in `profiles/base.nix`.
- Public SSH keys are stored in `ssh/` (not encrypted by design).

## Hosts
- `desktop`: Main workstation (Nvidia, libvirt).
- `laptop`: Portable machine (Intel).
- `frodo`: Headless home server (ZFS). See its dedicated [README](hosts/frodo/README.md).

## Credits

[Rofi Config](https://github.com/kianblakley/niri-land)
