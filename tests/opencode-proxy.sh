#!/usr/bin/env bash
# Offline regression tests: no real proxy, network, credentials or inference.
set -euo pipefail
repo=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
work=$(mktemp -d)
trap 'rm -rf -- "$work"' EXIT
export PROXY_TEST_ROOT="$work"
mkdir "$work/bin"
cat > "$work/bin/privoxy" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
config=$2
read -r _ address < "$config"
port=${address##*:}
if ! mkdir "$PROXY_TEST_ROOT/port-$port" 2>/dev/null; then
  echo 'There may be another Privoxy or some other proxy running on port' >&2
  exit 1
fi
trap 'rmdir "$PROXY_TEST_ROOT/port-$port"; exit' TERM INT
cp "$config" "$PROXY_TEST_ROOT/config-$port"
echo "Listening on port $port on IP address 127.0.0.1" >&2
while :; do sleep 0.05; done
EOF
cat > "$work/bin/opencode" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
[[ "${1:-}" == --standalone ]]
shift
[[ "$HTTP_PROXY" == "$HTTPS_PROXY" && "$HTTP_PROXY" == "$http_proxy" && "$HTTP_PROXY" == "$https_proxy" ]]
[[ "$NO_PROXY" == localhost,127.0.0.1,::1 && "$no_proxy" == "$NO_PROXY" ]]
[[ ! -v ALL_PROXY && ! -v all_proxy ]]
port=${HTTP_PROXY##*:}
printf '%s\n' "$@" > "$PROXY_TEST_ROOT/args-$port"
printf '%s\n' "$port" > "$PROXY_TEST_ROOT/started-$port"
sleep 0.5
exit "${PROXY_TEST_EXIT:-0}"
EOF
# Force a collision: two concurrent starts first try the same local port.
cat > "$work/bin/shuf" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
if mkdir "$PROXY_TEST_ROOT/first-$PPID" 2>/dev/null; then
  echo 54321
else
  echo $((55000 + PPID % 1000))
fi
EOF
chmod +x "$work/bin/"*
export PATH="$work/bin:$PATH"
export ALL_PROXY=must-be-unset all_proxy=must-be-unset
bash "$repo/opencodeproxy.sh" 10.106.75.8:1080 --prompt 'a prompt with spaces' > "$work/one.log" 2>&1 &
one=$!
bash "$repo/opencodeproxy.sh" '[::1]:1081' run 'second prompt' > "$work/two.log" 2>&1 &
two=$!
wait "$one"
wait "$two"
started=("$work"/started-*)
[[ ${#started[@]} == 2 ]]
! compgen -G "$work/port-*" >/dev/null
grep -Fq 'forward-socks5 / 10.106.75.8:1080 .' "$work"/config-*
grep -Fq 'forward-socks5 / [::1]:1081 .' "$work"/config-*
grep -Fxq -- '--prompt' "$work"/args-*
grep -Fxq 'a prompt with spaces' "$work"/args-*
grep -Fxq 'second prompt' "$work"/args-*
for invalid in 'host' 'host:0' 'host:65536' $'host:1080\ndebug 1'; do
  status=0
  bash "$repo/opencodeproxy.sh" "$invalid" > /dev/null 2>&1 || status=$?
  [[ $status == 2 ]]
done
status=0
PROXY_TEST_EXIT=7 bash "$repo/opencodeproxy.sh" localhost:1080 > /dev/null 2>&1 || status=$?
[[ $status == 7 ]]
! compgen -G "$work/port-*" >/dev/null
echo 'PASS: private server, concurrent sessions, port collision retry, arguments, proxy environment, validation, exit status and cleanup'
