# Private Glance Statistics page

Frodo's Glance dashboard gains a **Statistics** page alongside Media. Snapshot
collection and widget refresh are approximately every 30 seconds. This covers
Frodo's configured services, not whole-machine telemetry from desktop/laptop.
No activation or restart is performed by building/testing the configuration.

## What the numbers mean

- **Web requests:** completed HTTP requests reaching each configured Caddy site
  in the last 24 hours, limited to retained logs. Includes successful requests
  and HTTP 4xx/5xx, which are not automatically attacks. WebSockets and long
  streaming requests may not be logged until they finish. Each page may produce
  many requests, and each IP may represent many devices/people.
- **Source IPs:** direct socket peers, classified as LAN, WireGuard, other private
  networks or public IPs. The top 100 service/IP pairs are shown. Arbitrary
  forwarding headers are not trusted. No external geolocation API is called,
  and countries are not inferred. A future trusted proxy/tunnel integration
  needs an explicit client-IP trust policy; otherwise its address is shown.
- **Direct TCP now:** established connections to monitored local service ports,
  excluding loopback health checks and proxy-to-backend legs. Sampling misses
  short-lived connections. The HTTPS gateway row combines all sites; HTTP/2
  multiplexing means these are not request or user counts. Direct backend
  requests bypassing Caddy have no historical HTTP-request metric here.
- **WireGuard:** hashed public-peer identifiers, observed endpoint IPs, last
  successful handshake and received/sent byte counters. A recent handshake is
  within three minutes, not a persistent TCP session. Byte counters are since
  interface/peer reset. Private keys, preshared keys and wg0.conf are never read.
  Unauthenticated UDP scans are not counted as peers or failed login attempts.

Cloudflare's edge-only requests, DNS query counts, outbound torrent peer traffic,
and arbitrary services outside the configured inventory are **not** included.
The DDNS token is not reused or broadened to collect Cloudflare analytics.
History starts after deployment; there is no retrospective backfill.

## Data protection and privileges

Caddy writes filtered JSON access logs under `/var/log/caddy-traffic`, readable
only by Caddy and a dedicated statistics group. It drops request/response headers,
URI/path/query strings, TLS details and user IDs before writing the log. No
request/response bodies, cookies, authentication values, chat contents or model
credentials are captured by this feature. Six rolled 10 MiB files plus the active
file bound storage (rolled logs expire after seven days, at rotation). Rotation
may shorten the available 24-hour history; the UI calls it retained history.

An unprivileged `DynamicUser` collector reads these logs and socket metadata.
It has no capabilities, Docker access or service-control privileges. It scans
at most eight files/80 MiB per run; limits and unavailable/stale data produce
warnings instead of silently claiming a complete history.

WireGuard's kernel API needs privileges, so a separate root oneshot has only
`CAP_NET_ADMIN` and queries exactly `endpoints`, `latest-handshakes` and `transfer`.
It does not use secret-bearing `dump`, `showconf`, `private-key` or `preshared-keys`
commands, and publishes only a bounded explicit schema. This privileged collector
is not exposed as an API and cannot be controlled from Glance.

Only sanitized summaries are read-only mounted into Glance's existing asset
namespace at `/assets/traffic/statistics.json`. Source IPs are still private
metadata: do not publish/export this dashboard or JSON to the public website.

A narrow guard keeps TCP 8080 and both dashboard Caddy names (`frodo.local`,
`glance.frodo.local`) accessible only from localhost, `192.168.1.0/24`,
`10.100.0.0/24`, and IPv6 link-local sources. Other service ports/proxies and VPN
peer permissions are unchanged. This does not reinstate the postponed fleet-wide
hardening. If LAN/VPN addressing changes, update this guard deliberately.

## Deploy and check

```sh
nix run .#rebuild-frodo
```

Open `https://glance.frodo.local` (or `https://frodo.local`) and select
**Statistics**. No reboot is needed. Caddy/Glance configuration reloads are part
of the rebuild; Pi's persistent session daemon is not intentionally restarted.

```sh
ssh gustl@frodo.local 'systemctl status glance-traffic.timer; journalctl -u glance-traffic -u glance-wireguard -n 30 --no-pager'
```

No new listener, API token, provider account, or router port forward is needed.
For Wi-Fi/mobile WireGuard access, private DNS/router setup is still required.

## Verification

```sh
python3 -B -m unittest discover -s tests -p 'test_glance_traffic.py' -v
nix build --offline --impure --no-link --file tests/glance-traffic-vm.nix
```

The VM checks real Caddy redaction, service/source counts, the non-secret kernel
reader, DynamicUser/group permissions, page rendering, read-only nested asset
mounts, rejection of non-private dashboard sources, and restart behavior.
