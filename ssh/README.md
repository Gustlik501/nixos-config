# ssh/

Plain public keys and access policy references.

## Files

- `ssh/public-keys/laptop.pub`
- `ssh/public-keys/desktop.pub`

## Access matrix

- `hosts/frodo/default.nix` authorizes: laptop + desktop
- `hosts/desktop/default.nix` authorizes: laptop

Only private keys are encrypted in `secrets/*/ssh-user.yaml`.
