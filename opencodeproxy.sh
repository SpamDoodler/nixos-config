#!/usr/bin/env bash
set -euo pipefail

server="${1:-10.106.75.8:1080}"
if (($#)); then shift; fi
opencode_bin="${OPENCODE_PROXY_BIN:-opencode}"
case "$server" in
  socks5://*|socks5h://*) server=${server#*://} ;;
esac

# Only accept a SOCKS5 endpoint, never arbitrary Privoxy configuration text.
if [[ ! "$server" =~ ^([a-zA-Z0-9_.-]+|\[[a-fA-F0-9:.%_-]+\]):([0-9]{1,5})$ ]]; then
  printf 'Invalid SOCKS5 proxy: use HOST:PORT, [IPv6]:PORT or socks5://HOST:PORT (no credentials)\n' >&2
  exit 2
fi
server_port="${BASH_REMATCH[2]}"
if ((10#$server_port < 1 || 10#$server_port > 65535)); then
  printf 'Invalid SOCKS5 proxy port: %s\n' "$server_port" >&2
  exit 2
fi

for cmd in privoxy "$opencode_bin" shuf grep; do
  command -v "$cmd" >/dev/null || {
    printf 'Missing command: %s\n' "$cmd" >&2
    exit 1
  }
done

tempdir=$(mktemp -d)
config="$tempdir/config"
log="$tempdir/log"
pid=""
child=""
stop_privoxy() {
  if [[ -n "$pid" ]]; then
    kill "$pid" 2>/dev/null || true
    wait "$pid" 2>/dev/null || true
    pid=""
  fi
}
cleanup() {
  if [[ -n "$child" ]]; then
    kill "$child" 2>/dev/null || true
    wait "$child" 2>/dev/null || true
  fi
  stop_privoxy
  rm -rf -- "$tempdir"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
trap 'exit 129' HUP

# Bind first, then confirm readiness from this process's own startup log.
# A collision cannot accidentally connect us to another session's listener.
ready=0
for ((attempt=0; attempt<20; attempt++)); do
  port=$(shuf -i 49152-65535 -n 1)
  printf 'listen-address 127.0.0.1:%s\nforward-socks5 / %s .\ndebug 4096\n' \
    "$port" "$server" > "$config"
  privoxy --no-daemon "$config" > "$log" 2>&1 &
  pid=$!
  for ((tick=0; tick<100; tick++)); do
    if ! kill -0 "$pid" 2>/dev/null; then break; fi
    if grep -Fq "Listening on port $port " "$log"; then
      ready=1
      break
    fi
    sleep 0.05
  done
  if ((ready)); then break; fi
  stop_privoxy
  # Only retry address collisions; report other configuration/startup errors.
  if ! grep -Eqi 'address already in use|already.*listen|another.*privoxy' "$log"; then
    break
  fi
done
if ((!ready)); then
  printf 'Privoxy failed to start:\n' >&2
  cat -- "$log" >&2
  exit 1
fi

printf 'Privoxy listening on 127.0.0.1:%s; upstream SOCKS5 %s (not yet tested)\n' "$port" "$server" >&2
export HTTP_PROXY="http://127.0.0.1:$port"
export HTTPS_PROXY="$HTTP_PROXY"
export http_proxy="$HTTP_PROXY"
export https_proxy="$HTTP_PROXY"
# OpenCode consults protocol-specific overrides before HTTP(S)_PROXY.
export WS_PROXY="$HTTP_PROXY" WSS_PROXY="$HTTP_PROXY"
export ws_proxy="$HTTP_PROXY" wss_proxy="$HTTP_PROXY"
export NO_PROXY=localhost,127.0.0.1,::1
export no_proxy="$NO_PROXY"
unset ALL_PROXY all_proxy

# Background + wait lets signal traps promptly clean up both children. Explicit
# stdin redirection preserves terminal input for the interactive OpenCode TUI.
# The shared background service predates these proxy variables. A private
# server is essential: it must inherit this session's proxy environment.
"$opencode_bin" --standalone "$@" <&0 &
child=$!
status=0
wait "$child" || status=$?
child=""
exit "$status"
