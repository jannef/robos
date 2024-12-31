#!/usr/bin/env bash
#
# install-otel-collector.sh
#
# Installs OpenTelemetry Collector Contrib for ARM64 (version 0.116.0),
# sets up a minimal config with journald->Azure Monitor,
# deploys a systemd service, and starts it.
#
# Usage:
#   ./install-otel-collector.sh "<YOUR_CONNECTION_STRING>"
#
# Notes:
#   - Expects otel-collector.service in the same folder as this script.
#   - Overwrites /etc/otel-collector/config.yaml.
#   - Make sure your service file references the correct otelcol-contrib path
#     and /etc/otel-collector/config.yaml (or your chosen config path).

set -euo pipefail

# -- 1. Check for parameter: Azure Monitor connection string --
if [ "$#" -lt 1 ]; then
  echo "Usage: $0 <AZURE_MONITOR_CONNECTION_STRING>"
  exit 1
fi

CONNECTION_STRING="$1"

# -- 2. Variables for OTEL Contrib Download --
VERSION="0.116.0"
ARCH="arm64"
TARBALL="otelcol-contrib_${VERSION}_linux_${ARCH}.tar.gz"
RELEASE_URL="https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download/v${VERSION}"
DOWNLOAD_URL="${RELEASE_URL}/${TARBALL}"

# -- 3. Download & Install OTEL Collector Contrib --
echo ">>> Downloading otelcol-contrib v${VERSION} for ${ARCH}..."
wget -q "${DOWNLOAD_URL}"

echo ">>> Extracting tarball..."
tar xzf "${TARBALL}"

echo ">>> Moving binary to /usr/local/bin/otelcol-contrib..."
sudo mv -f otelcol-contrib /usr/local/bin/otelcol-contrib
sudo chmod 755 /usr/local/bin/otelcol-contrib

echo ">>> Cleaning up tarball..."
rm -f "${TARBALL}"

# -- 4. Create /etc/otel-collector/config.yaml with journald->Azure Monitor --
echo ">>> Creating /etc/otel-collector/config.yaml with your connection string..."
sudo mkdir -p /etc/otel-collector

# Minimal config using journald receiver and azuremonitor exporter
# If you want to read older logs too, set: start_at: beginning
# Or if you only want new logs, use: start_at: end
cat <<EOF | sudo tee /etc/otel-collector/config.yaml >/dev/null
receivers:
  journald:
    directory: /run/log/journal
    # start_at: end
processors:
  batch:
exporters:
  azuremonitor:
    connection_string: "${CONNECTION_STRING}"
service:
  pipelines:
    logs:
      receivers: [journald]
      processors: [batch]
      exporters: [azuremonitor]
EOF

# -- 5. Copy systemd service file (from same directory as script) --
SERVICE_SRC="$(cd "$(dirname "$0")" && pwd)/otel-collector.service"
SERVICE_DEST="/etc/systemd/system/otel-collector.service"

echo ">>> Copying ${SERVICE_SRC} to ${SERVICE_DEST}..."
sudo cp -f "${SERVICE_SRC}" "${SERVICE_DEST}"

# -- 6. Enable & Start the service --
echo ">>> Enabling and starting otel-collector..."
sudo systemctl daemon-reload
sudo systemctl enable otel-collector
sudo systemctl start otel-collector

echo ">>> Done!"
echo "Check status with:  systemctl status otel-collector"
echo "View logs with:    journalctl -u otel-collector -f"
echo "Ensure data is arriving in Azure Monitor using your connection string."
