#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SYSTEMD_USER_DIR="${HOME}/.config/systemd/user"

HUGO_SERVICE="snjlogs-hugo.service"
ISSO_SERVICE="snjlogs-isso.service"

HUGO_PORT="${HUGO_PORT:-1313}"
ISSO_PORT="${ISSO_PORT:-1212}"

need_systemctl_user() {
  if ! command -v systemctl >/dev/null 2>&1; then
    echo "systemctl is not installed or not in PATH." >&2
    exit 1
  fi
}

write_services() {
  mkdir -p "$SYSTEMD_USER_DIR"

  cat >"${SYSTEMD_USER_DIR}/${HUGO_SERVICE}" <<EOF
[Unit]
Description=SNJ Logs Hugo development server
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
WorkingDirectory=${ROOT_DIR}
ExecStart=/usr/bin/env hugo server --bind 0.0.0.0 --baseURL http://localhost:${HUGO_PORT} --port ${HUGO_PORT}
Restart=always
RestartSec=5

[Install]
WantedBy=default.target
EOF

  cat >"${SYSTEMD_USER_DIR}/${ISSO_SERVICE}" <<EOF
[Unit]
Description=SNJ Logs Isso comment server
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
WorkingDirectory=${ROOT_DIR}/isso
ExecStart=${ROOT_DIR}/isso/start.sh
Restart=always
RestartSec=5

[Install]
WantedBy=default.target
EOF

  systemctl --user daemon-reload
}

enable_linger() {
  if command -v loginctl >/dev/null 2>&1; then
    loginctl enable-linger "$USER" 2>/dev/null || true
  fi
}

install_services() {
  need_systemctl_user
  write_services
  systemctl --user enable "$HUGO_SERVICE" "$ISSO_SERVICE"
  enable_linger
  echo "Installed and enabled services:"
  echo "  ${HUGO_SERVICE}"
  echo "  ${ISSO_SERVICE}"
}

start_services() {
  need_systemctl_user
  write_services
  systemctl --user enable --now "$HUGO_SERVICE" "$ISSO_SERVICE"
  enable_linger
  echo "Started Hugo on http://localhost:${HUGO_PORT}"
  echo "Started Isso on http://localhost:${ISSO_PORT}"
}

stop_services() {
  need_systemctl_user
  systemctl --user stop "$HUGO_SERVICE" "$ISSO_SERVICE"
  echo "Stopped Hugo and Isso."
}

restart_services() {
  need_systemctl_user
  write_services
  systemctl --user restart "$HUGO_SERVICE" "$ISSO_SERVICE"
  echo "Restarted Hugo and Isso."
}

status_services() {
  need_systemctl_user
  systemctl --user status "$HUGO_SERVICE" "$ISSO_SERVICE" --no-pager
}

logs_services() {
  need_systemctl_user
  journalctl --user -u "$HUGO_SERVICE" -u "$ISSO_SERVICE" -f
}

disable_services() {
  need_systemctl_user
  systemctl --user disable --now "$HUGO_SERVICE" "$ISSO_SERVICE"
  echo "Disabled and stopped Hugo and Isso."
}

usage() {
  cat <<EOF
Usage: ./manage-servers.sh <command>

Commands:
  install   Create and enable user systemd services
  start     Create, enable, and start both services
  stop      Stop both services
  restart   Restart both services
  status    Show service status
  logs      Follow service logs
  disable   Stop and disable both services

Environment:
  HUGO_PORT  Defaults to 1313
  ISSO_PORT  Defaults to 1212
EOF
}

case "${1:-}" in
  install) install_services ;;
  start) start_services ;;
  stop) stop_services ;;
  restart) restart_services ;;
  status) status_services ;;
  logs) logs_services ;;
  disable) disable_services ;;
  -h|--help|help|"") usage ;;
  *)
    echo "Unknown command: $1" >&2
    usage >&2
    exit 1
    ;;
esac
