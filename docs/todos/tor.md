# Tor and Snowflake

Priority: **P1**. The current configuration is neither a working relay nor a
useful client for any application, and it runs at boot for no benefit.

## Current state

`system/services.nix:36-82`:

- Tor is enabled with `client.enable = true`, `torsocks.enable = true`, and a
  long list of relay settings.
- The generated `/nix/store/...-torrc` contains **no `ORPort`**, so Tor runs
  client-only.
- `enableGeoIP = false` while `ExitNodes = "{ch} StrictNodes 1"` requires GeoIP.
  The journal warns that country filtering cannot work.
- `StrictNodes` is a separate directive, not part of the `ExitNodes` value.
- `ExitPolicy = ["reject *:*"]` and the relay bandwidth/nickname settings are
  no-ops in client-only mode.
- `ss` shows no listener on 443 and no application is configured to use the
  SOCKS proxy. Nothing on the system automatically routes through Tor.
- Snowflake proxy is enabled at boot (`services.snowflake-proxy`).

Conclusion: this is dead configuration with misleading intent. It also adds a
background daemon and attack surface.

## Decision

The user said Tor and Snowflake can go. **Remove both** unless a concrete use
appears. Tor Browser, if kept, ships its own Tor process and does not need the
system daemon.

- [ ] Remove `services.tor` from `system/services.nix`.
- [ ] Remove `services.snowflake-proxy`.
- [ ] Remove `tor-browser` from `home/packages.nix` if it is not used.
- [ ] Remove `torsocks` if no CLI tool needs it.
- [ ] Remove any Tor-related firewall expectation (there is no open 443 now).

## Answer: Home Manager or NixOS module?

**NixOS module**, not Home Manager, if Tor is ever reintroduced.

Reasons:

- Tor is a system daemon that should start before login and run independently
  of a graphical session.
- It needs `/var/lib/tor`, a stable user/group, and systemd system services.
- Relay mode needs firewall ports and boot ordering.
- NixOS has a first-class `services.tor` module; Home Manager does not provide a
  comparable system service.
- A user-level Tor would only serve one user and would still need firewall
  changes for a relay.

Put it in a dedicated `system/tor.nix` imported by `system/system.nix`, not in
`home/`. Keep Tor Browser in Home Manager if you use it; the browser is a user
application, the daemon is not.

## If you reinstate a client-only Tor

Minimal, coherent config:

```nix
services.tor = {
  enable = true;
  client.enable = true;
  torsocks.enable = true;   # only if you use torsocks
  settings = {
    SocksPort = "127.0.0.1:9050";
    # Do not set ORPort, ExitNodes, ExitPolicy, or relay bandwidth.
  };
};
```

Then explicitly route an application through `127.0.0.1:9050` (or use
`torsocks <command>`). Tor is not a VPN and does not transparently protect the
whole system.

## If you actually want a relay

Do not use the current half-relay config. A middle relay needs:

- `ORPort = 443` (or another reachable port) and a firewall opening;
- a realistic `RelayBandwidthRate`/`Burst` in **MB/s** (for a laptop uplink,
  1–5 MB/s is already generous);
- `Nickname`, `ContactInfo`, and `ExitPolicy = ["reject *:*"]`;
- `enableGeoIP = true` only if you use country restrictions;
- `ExitNodes` only for a client, not a relay;
- monitoring and a stable network.

Running an exit relay from a home connection is not recommended: abuse
complaints, ISP issues, and legal exposure. A middle relay is less risky but
still consumes bandwidth.

## Snowflake

Snowflake proxy helps censored users but consumes bandwidth and runs
continuously. It is not needed on a laptop. Remove it. If you want to
contribute later, run it manually or on a server, not at boot on this machine.

## Verification

```sh
systemctl status tor snowflake-proxy --no-pager
ss -lntp | grep -E ':9050|:443' || true
journalctl -u tor -b --no-pager | tail -20
```

After removal, `systemctl status tor` should report not-found and no Tor
process should be running.

## Open questions

- Is Tor Browser actually used? If yes, keep the browser only.
- Do you need `torsocks` for any CLI workflow?
- If a relay is desired later, is a VPS a better host than this laptop?