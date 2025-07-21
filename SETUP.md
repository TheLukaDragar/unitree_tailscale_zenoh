# Zenoh DDS Bridge Setup for Go2 Robot

## What's Installed

### Files Created:
- `/unitree/zenoh/zenoh-bridge-dds` - Main executable
- `/unitree/zenoh/config.json5` - Configuration file
- `/unitree/zenoh/setup_dev_machine.sh` - macOS setup script
- `/unitree/zenoh/test_bridge.sh` - Test script
- `/etc/systemd/system/zenoh-bridge-dds.service` - System service

### Service Status:
- **Service**: `zenoh-bridge-dds.service` 
- **Status**: Active and enabled (auto-starts on boot)
- **Port**: 7447 (zenoh), 8000 (REST API)

## Quick Commands

### Check Status:
```bash
systemctl status zenoh-bridge-dds
curl http://localhost:8000/@/*/dds/version
```

### Restart Service:
```bash
systemctl restart zenoh-bridge-dds
```

### View Logs:
```bash
journalctl -fu zenoh-bridge-dds
```

### Test Everything:
```bash
/unitree/zenoh/test_bridge.sh
```

## Development Machine Setup (macOS):

1. Copy setup script:
```bash
scp root@100.92.165.120:/unitree/zenoh/setup_dev_machine.sh ~/setup_zenoh.sh
```

2. Run setup:
```bash
chmod +x ~/setup_zenoh.sh && ~/setup_zenoh.sh
```

3. Start bridge:
```bash
cd ~/zenoh && ./start_bridge.sh
```

## Network Access:

- **Robot IP**: 100.92.165.120 (Tailscale) or 10.106.5.64 (local)
- **Robot REST API**: http://100.92.165.120:8000
- **Dev Machine REST API**: http://localhost:8001

## What It Does:

- Bridges all Go2 DDS topics to Zenoh protocol
- Adds "go2/" prefix to all topics
- Survives network interface switching (no more crashes)
- Enables remote access via Tailscale

Done. 