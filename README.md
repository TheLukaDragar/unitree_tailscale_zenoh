# Zenoh Bridge Setup for Go2 Robot

This setup solves the CycloneDDS interface switching crashes when the Go2 robot switches between network modes (AP ↔ STA).

## Problem Solved

- ✅ **CycloneDDS crashes** when switching from wlan1 (AP) to wlan0 (STA)
- ✅ **Interface dependency** issues with CycloneDDS
- ✅ **Remote development** over Tailscale network

## Setup

### 1. On Your Development Machine (Mac)

```bash
# Run the setup script
./setup_dev_machine.sh

# Start the bridge
cd ~/zenoh && ./start_bridge.sh
```

### 2. On Your Go2 Robot

```bash
# Copy and run the robot setup script
scp setup_robot.sh root@<robot-tailscale-ip>:/tmp/
ssh root@<robot-tailscale-ip>
chmod +x /tmp/setup_robot.sh
/tmp/setup_robot.sh

# Start the bridge service
sudo systemctl start zenoh-bridge-dds
```

## How It Works

```
Robot DDS ← zenoh-bridge ↔ Tailscale Network ↔ zenoh-bridge → Your Mac DDS
          (scope: go2)                              (scope: go2)
```

Both bridges use the same **"go2" scope** to ensure proper routing.

## Testing

```bash
# Test the connection
cd ~/zenoh && ./test_connection.sh

# Test DDS subscriber
cd ~/Downloads/unitree_code/luka_code
uv run src/luka_robot/lowlevel_subscriber_test.py
```

## Key Configuration

- **Robot Tailscale IP**: `100.92.165.120:7447`
- **Scope**: `go2` (must match on both sides)
- **DDS Domain**: `0`
- **REST API**: `http://localhost:8001`

## Benefits

- **Network mode switching** without crashes
- **Remote development** via Tailscale
- **Stable DDS communication** across interface changes
- **Easy monitoring** via REST API

## Troubleshooting

### No Data Received
1. Check both bridges are running with same scope
2. Verify Tailscale connectivity: `ping 100.92.165.120`
3. Check routes: `curl 'http://localhost:8001/@/*/dds/route/**'`

### Bridge Won't Start
1. Use command line args instead of config file
2. Check port 8001 is available
3. Verify zenoh-bridge-dds binary is executable

### Connection Issues
1. Ensure robot bridge is running: `ssh root@robot "systemctl status zenoh-bridge-dds"`
2. Check Tailscale status: `tailscale status`
3. Verify firewall allows port 7447 