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
Pi Web workstation tunnels reuse that same secret through its canonical runtime
path `/run/secrets/ssh_user_ed25519_key`, without exposing home directories to
the tunnel service. Keep `ssh/desktop.pub` and `ssh/laptop.pub` matched to these
private keys; Frodo declaratively authorizes them for the restricted machine
accounts. Rotating the secret requests a tunnel restart.

## Pi Web credentials

Browser-password provisioning and the option to use a SOPS-decrypted bcrypt hash
are described in [the Pi Web guide](../docs/pi-web.md). Model-provider credentials
stay in each runtime user's local Pi profile and are not copied into this repo.

## Public keys (plaintext)

Public keys are intentionally stored in git:

- `ssh/laptop.pub`
- `ssh/desktop.pub`

Authorization matrix:

- `frodo` accepts `laptop.pub` and `desktop.pub`
- `desktop` accepts `laptop.pub`
- Frodo's restricted `pi-web-desktop` account accepts only `desktop.pub`
- Frodo's restricted `pi-web-laptop` account accepts only `laptop.pub`
