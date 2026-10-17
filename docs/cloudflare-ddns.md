# Cloudflare DDNS on Frodo

A Nix-packaged Bash updater (`modules/services/cloudflare-ddns.sh`) checks roughly
every five minutes through `cloudflare-ddns.timer`; no cron or npm installation.
It runs as an unprivileged dynamic user and reads its token through systemd
credentials. This does not publish a web service, forward router ports, restart
WireGuard, or change LAN access.

## What it updates

Only two **existing A records**: the zone apex and the VPN hostname. The apex is
currently proxied; the VPN record is DNS-only. PATCH changes only their IP,
preserving proxy status, TTL, comments and tags. Existing `www`, `seerr`, `vault`,
and `jelly` CNAMEs pointing at the apex already follow it and are not edited.

Both names are SOPS secrets (`cloudflare_ddns_zone`, `wireguard_endpoint`),
rendered into a root-only environment file at activation, because naming the
DNS-only record in this public repo would point readers at the home IP.

Create a record in the Cloudflare dashboard **before** deploying a new name: a
missing record makes the updater skip *every* record, including the apex. To
rotate the VPN hostname: add the new DNS-only A record with the current home IP,
update `wireguard_endpoint`, deploy, change each client's `Endpoint` line, test
on mobile data, then delete the old record.

The updater checks two independent HTTPS IPv4 services and rejects disagreeing,
private, malformed or reserved addresses. It checks the whole record allowlist
before updating; missing/duplicate A records or CNAME conversions fail closed.
Unchanged IPs produce no write calls. API errors fail the job and are retried on
the next timer run. Updates to two records are not a transaction: a failure after
the first PATCH may temporarily leave one stale; a later successful run repairs
it. This is IPv4-only and never creates AAAA records.

When the future website moves elsewhere, first drop the apex from the
`cloudflare-ddns.env` SOPS template in `hosts/frodo/default.nix`, or DDNS will
continue targeting home. Likewise,
Cloudflare Tunnel CNAMEs must not be managed by this updater.

## One-time API token setup

In Cloudflare: **My Profile → API Tokens → Create Token → Custom token**:

- Permission **Zone → DNS → Edit**.
- Permission **Zone → Zone → Read**, to discover the zone ID by name.
- Zone resources: **Include → Specific zone →** your zone only.
- Do **not** use the Global API Key or account-wide permissions.
- Do not restrict the token to your current WAN IP: that would break DDNS exactly
  when that IP changes. Set an expiry only if you also plan token renewal.

Cloudflare grants DNS edit authority for the zone, not just these two records;
the script's allowlist is an additional guard, not a token permission boundary.
Keep the token private. Never paste it in chat, command-line arguments or Git.

The repository has an **empty** `cloudflare_ddns_token` placeholder. The job
skips itself until the token is provisioned. On your trusted admin machine:

```sh
sops secrets/frodo/secrets.yaml
```

In the decrypted editor, replace only `cloudflare_ddns_token: ""` with the token,
then save/exit so SOPS encrypts it. The same file holds `cloudflare_ddns_zone`
(the apex) and `wireguard_endpoint` (the full VPN hostname); keep the domain out
of every plaintext file, commit message and test fixture. Leave every other secret
unchanged. Frodo
installs this as a root-only `0400` secret; systemd privately passes it to the
updater. No plaintext token enters the Nix store or the process command line.

Then deploy (new module/script files must be added to Git for flake visibility):

```sh
nix run .#rebuild-frodo
ssh -t gustl@frodo.local 'sudo systemctl start cloudflare-ddns.service'
ssh gustl@frodo.local 'systemctl status cloudflare-ddns.timer; journalctl -u cloudflare-ddns.service -n 25 --no-pager'
```

An empty token results in a skipped service, not an unauthenticated request.
A non-empty invalid/expired token fails visibly without exposing the token in
logs. After a token rotation, SOPS requests an updater run. You do not need to
restart WireGuard, regenerate peers, or edit clients using the VPN hostname.

## VPN caveats

Keep the VPN record **DNS-only**, and configure the router's UDP 51820 forward to
Frodo separately. Updating DNS cannot bypass CGNAT/double NAT. An already-running
WireGuard client may retain the previously resolved endpoint IP; toggling its
tunnel reconnects using fresh DNS. Router NAT-loopback support affects testing
from the home LAN, so test remote access on mobile data.

## Offline verification

```sh
nix build --offline --impure --no-link --file tests/cloudflare-ddns.nix
nix build --offline --impure --no-link --file tests/cloudflare-ddns-vm.nix
```

All fixtures are local; these tests never call real IP providers or Cloudflare.
