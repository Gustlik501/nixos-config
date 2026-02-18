# secrets/

Encrypted secrets for `sops-nix` live here.

## Layout

- `secrets/frodo/*.yaml`
- `secrets/desktop/*.yaml`
- `secrets/laptop/*.yaml`
- `secrets/vm/*.yaml`

## First bootstrap (admin machine)

1. Create your admin age key:
   - `mkdir -p ~/.config/sops/age`
   - `age-keygen -o ~/.config/sops/age/keys.txt`
   - `age-keygen -y ~/.config/sops/age/keys.txt`
2. Update `.sops.yaml` recipients with real `age1...` public keys.
3. Encrypt/edit a secret:
   - `sops secrets/laptop/ssh-user.yaml`
   - `sops secrets/desktop/ssh-user.yaml`

## Host runtime key

On each host (once):

1. `sudo mkdir -p /var/lib/sops-nix`
2. `sudo age-keygen -o /var/lib/sops-nix/key.txt`
3. `sudo chmod 600 /var/lib/sops-nix/key.txt`
4. `sudo age-keygen -y /var/lib/sops-nix/key.txt`
5. Add that public key to `.sops.yaml`, then re-encrypt host files with `sops updatekeys`.

## SSH user private keys (encrypted)

Templates:

- `secrets/laptop/ssh-user.yaml`
- `secrets/desktop/ssh-user.yaml`

Each file must contain:

- `ssh_user_ed25519_key`: full private key block

Example value:

```yaml
ssh_user_ed25519_key: |
  -----BEGIN OPENSSH PRIVATE KEY-----
  ...
  -----END OPENSSH PRIVATE KEY-----
```

Then flip these toggles:

- `hosts/laptop/default.nix`: `my.security.sopsSshUserKey.enable = true;`
- `hosts/desktop/default.nix`: `my.security.sopsSshUserKey.enable = true;`

## Public keys (plaintext)

Public keys are intentionally stored in git:

- `ssh/public-keys/laptop.pub`
- `ssh/public-keys/desktop.pub`

Authorization matrix:

- `frodo` accepts `laptop.pub` and `desktop.pub`
- `desktop` accepts `laptop.pub`
