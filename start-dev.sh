#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

# --- Podman Compose ---
echo "Ensuring podman-compose services are up..."
if podman compose ps 2>/dev/null | grep -q "Up"; then
  echo "  Services already running."
else
  podman compose up -d
  echo "  Postgres started."
fi

# --- Cleanup on exit ---
cleanup() {
  echo ""
  echo "Shutting down..."
  kill 0 2>/dev/null
  wait 2>/dev/null
}
trap cleanup EXIT INT TERM

# --- Host app (Spring Boot) ---
echo "Starting host app..."
./mvnw -q spring-boot:run &

# --- Plugins ---
for dir in plugins/*/; do
  if [ -f "$dir/package.json" ]; then
    name=$(basename "$dir")
    echo "Starting plugin: $name"
    (cd "$dir" && npm install && npm run dev) &
  fi
done

echo ""
echo "All services starting. Press Ctrl+C to stop everything."
wait
