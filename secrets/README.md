# secrets/

Encrypted secrets for `sops-nix` live here.

## Layout

- `secrets/<host>/secrets.yaml` (default per-host file)

## First bootstrap (admin machine)

1. Create your admin age key:
   - `mkdir -p ~/.config/sops/age`
   - `age-keygen -o ~/.config/sops/age/keys.txt`
   - `age-keygen -y ~/.config/sops/age/keys.txt`
2. Update `.sops.yaml` recipients with real `age1...` public keys.
3. Encrypt/edit a secret:
   - `sops secrets/laptop/secrets.yaml`
   - `sops secrets/desktop/secrets.yaml`

## Host runtime key

On each host (once):

1. `sudo mkdir -p /var/lib/sops-nix`
2. `sudo age-keygen -o /var/lib/sops-nix/key.txt`
3. `sudo chmod 600 /var/lib/sops-nix/key.txt`
4. `sudo age-keygen -y /var/lib/sops-nix/key.txt`
5. Add that public key to `.sops.yaml`, then re-encrypt host files with `sops updatekeys`.

## SSH user private keys (encrypted)

Templates:

- `secrets/laptop/secrets.yaml`
- `secrets/desktop/secrets.yaml`

Each file must contain:

- `ssh_user_ed25519_key`: full private key block

Example value:

```yaml
ssh_user_ed25519_key: |
  -----BEGIN OPENSSH PRIVATE KEY-----
  ...
  -----END OPENSSH PRIVATE KEY-----
```

The base profile already declares `ssh_user_ed25519_key` for the main user in `profiles/base.nix`.

## Frodo Hermes Agent

`modules/services/hermes-agent.nix` declares a single `sops-nix` secret named
`hermes_env`. Add it to `secrets/frodo/secrets.yaml` with `sops`:

```yaml
hermes_env: |
  DISCORD_BOT_TOKEN=your-discord-bot-token
  DISCORD_ALLOWED_USERS=284102345871466496
```

Optional Discord settings can go in the same env block, for example:

```yaml
  DISCORD_HOME_CHANNEL=123456789012345678
  DISCORD_FREE_RESPONSE_CHANNELS=123456789012345678
```

`hermes_env` is one YAML string because Hermes expects an env file. The `|`
means "everything indented below this line is the file content"; each indented
line is a normal `KEY=value` environment line.

The OpenAI Codex provider does not use an API key here. After deploying Hermes,
log in once as the `hermes` service user so Hermes can store Codex OAuth
credentials under `/data/hermes/.hermes/auth.json`:

```sh
sudo -u hermes HERMES_HOME=/data/hermes/.hermes hermes auth add openai-codex
```

## Public keys (plaintext)

Public keys are intentionally stored in git:

- `ssh/laptop.pub`
- `ssh/desktop.pub`

Authorization matrix:

- `frodo` accepts `laptop.pub` and `desktop.pub`
- `desktop` accepts `laptop.pub`
