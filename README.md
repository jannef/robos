# OpenTelemetry Collector (Contrib) on Raspberry Pi (64-bit) – Quick Guide

## Enable Persistent Journald Logs
By default, Raspbian might store logs in memory (/run/log/journal), causing a new boot ID on every reboot. If you want logs (and the boot ID) to persist, follow these steps:


Create the persistent directory:

```bash
sudo mkdir -p /var/log/journal
sudo systemd-tmpfiles --create --prefix /var/log/journal
```

Configure journald to use persistent storage. Open /etc/systemd/journald.conf:

```bash
sudo nano /etc/systemd/journald.conf
```
and set (or uncomment) the following:

```ini
[Journal]
Storage=persistent
````

Restart systemd-journald:

```bash
sudo systemctl restart systemd-journald
````

Now logs will accumulate in /var/log/journal across reboots. This helps the collector maintain offsets more reliably.

> Rest of the steps can be accomplished by running **/rapberry-agent/otel-collector/install.sh**

## Download and Install
Check your architecture to confirm you’re on aarch64 (64-bit ARM):

```bash
uname -m
# Should output: aarch64
````

Download the desired version of OTEL Collector Contrib for ARM64. For example, version 0.116.0:

```bash
wget https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download/v0.116.0/otelcol-contrib_0.116.0_linux_arm64.tar.gz
tar xvf otelcol-contrib_0.116.0_linux_arm64.tar.gz
````

Move the binary to /usr/local/bin and set permissions:

```bash
sudo mv -f otelcol-contrib /usr/local/bin/otelcol-contrib
sudo chmod 755 /usr/local/bin/otelcol-contrib
```

## Configure and Run
Create a systemd service (if you haven’t already) so the collector starts on boot.

```bash
sudo nano /etc/systemd/system/otel-collector.service
```
Sample content:
```ini
[Unit]
Description=OpenTelemetry Collector Contrib
After=network.target

[Service]
ExecStart=/usr/local/bin/otelcol-contrib --config /etc/otel-collector/config.yaml
Restart=always

[Install]
WantedBy=multi-user.target
Create/adjust your config at /etc/otel-collector/config.yaml. For example:
yaml
Copy code
receivers:
  journald:
    directory: /run/log/journal
    # Optional: start_at: end
    # Optional: units: ["myapp.service"]

processors:
  batch:

exporters:
  azuremonitor:
    connection_string: "<YOUR_CONNECTION_STRING>"

service:
  pipelines:
    logs:
      receivers: [journald]
      processors: [batch]
      exporters: [azuremonitor]
```

Enable and start the collector:
```bash
sudo systemctl daemon-reload
sudo systemctl enable otel-collector
sudo systemctl start otel-collector
```

Check logs to ensure it’s running:
```bash
journalctl -u otel-collector -f
```

## Verify
Confirm the Collector is running:

```bash
systemctl status otel-collector
```

Look for logs in your target destination (e.g., Azure Monitor / Application Insights). It may take a few minutes for telemetry to appear.
