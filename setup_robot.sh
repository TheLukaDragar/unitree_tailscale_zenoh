#!/bin/bash
# Setup script for zenoh-bridge-dds on Go2 robot
# This solves the CycloneDDS interface switching crash issue

echo "🤖 Setting up zenoh-bridge-dds on Go2 robot..."

# Get Tailscale IP
if command -v tailscale >/dev/null 2>&1; then
    ROBOT_TAILSCALE_IP=$(tailscale ip -4)
    echo "📡 Robot Tailscale IP: $ROBOT_TAILSCALE_IP"
else
    echo "⚠️  Tailscale not found. Using local IP instead..."
    ROBOT_TAILSCALE_IP=$(hostname -I | awk '{print $1}')
    echo "📡 Robot IP: $ROBOT_TAILSCALE_IP"
fi

# Create zenoh directory
sudo mkdir -p /unitree/zenoh
cd /unitree/zenoh

# Download latest zenoh-bridge-dds for ARM64
echo "📥 Downloading zenoh-bridge-dds for ARM64..."
LATEST_VERSION="1.4.0"
ZIP_FILE="zenoh-bridge-dds-${LATEST_VERSION}-aarch64-unknown-linux-gnu.zip"

if command -v wget >/dev/null 2>&1; then
    wget "https://download.eclipse.org/zenoh/zenoh-plugin-dds/latest/aarch64-unknown-linux-gnu/${ZIP_FILE}"
elif command -v curl >/dev/null 2>&1; then
    curl -L -o "${ZIP_FILE}" "https://download.eclipse.org/zenoh/zenoh-plugin-dds/latest/aarch64-unknown-linux-gnu/${ZIP_FILE}"
else
    echo "❌ Neither wget nor curl found. Please install one of them."
    exit 1
fi

# Extract and setup
echo "📦 Extracting and setting up..."
unzip -o "${ZIP_FILE}"
chmod +x zenoh-bridge-dds
sudo ln -sf /unitree/zenoh/zenoh-bridge-dds /usr/local/bin/zenoh-bridge-dds

# Create robot configuration
echo "⚙️ Creating robot configuration..."
cat > config.json5 << EOF
{
  "mode": "peer",
  "listen": {
    "endpoints": [
      "tcp/${ROBOT_TAILSCALE_IP}:7447",
      "tcp/127.0.0.1:7447",
      "tcp/0.0.0.0:7447"
    ]
  },
  "plugins": {
    "dds": {
      "domain": 0,
      "scope": "go2",
      "localhost_only": false,
      "allow": ".*"
    },
    "rest": {
      "http_port": "8000"
    }
  }
}
EOF

# Create systemd service
echo "🔧 Creating systemd service..."
sudo cat > /etc/systemd/system/zenoh-bridge-dds.service << 'EOF'
[Unit]
Description=Zenoh DDS Bridge for Go2 Robot
After=network.target tailscaled.service
Wants=network.target
Requires=tailscaled.service

[Service]
Type=simple
ExecStart=/usr/local/bin/zenoh-bridge-dds --mode peer --listen tcp/0.0.0.0:7447 --domain 0 --scope go2 --rest-http-port 8000
Restart=always
RestartSec=5
User=root
Environment=PATH=/usr/local/bin:/usr/bin:/bin
WorkingDirectory=/unitree/zenoh

[Install]
WantedBy=multi-user.target
EOF

# Create test script
echo "🧪 Creating test script..."
cat > test_bridge.sh << 'EOF'
#!/bin/bash
echo "🧪 Testing zenoh bridge on Go2 robot..."
echo ""

echo "📊 Service status:"
systemctl status zenoh-bridge-dds --no-pager

echo ""
echo "🌐 REST API test:"
curl -s http://localhost:8000/@/*/dds/version || echo "❌ REST API not responding"

echo ""
echo "🔗 Active routes:"
curl -s 'http://localhost:8000/@/*/dds/route/**' | head -10

echo ""
echo "📡 Network listening:"
ss -tlnp | grep :7447 || echo "❌ Not listening on port 7447"

echo ""
echo "🏃 DDS topics being bridged:"
curl -s 'http://localhost:8000/@/*/dds/route/**/rt/lowstate' 2>/dev/null && echo "✅ lowstate topic found" || echo "❌ lowstate topic not found"
EOF

chmod +x test_bridge.sh

# Enable and configure service
sudo systemctl daemon-reload
sudo systemctl enable zenoh-bridge-dds.service

echo "✅ zenoh-bridge-dds setup complete on Go2 robot!"
echo ""
echo "🚀 To start the bridge:"
echo "   sudo systemctl start zenoh-bridge-dds"
echo ""
echo "📊 To check status:"
echo "   sudo systemctl status zenoh-bridge-dds"
echo ""
echo "🧪 To test the setup:"
echo "   /unitree/zenoh/test_bridge.sh"
echo ""
echo "🌐 REST API will be available at:"
echo "   http://${ROBOT_TAILSCALE_IP}:8000 (via Tailscale)"
echo "   http://localhost:8000 (local)"
echo ""
echo "🔧 Service configuration:"
echo "   - Auto-starts on boot"
echo "   - Listens on all interfaces (0.0.0.0:7447)"
echo "   - Uses scope 'go2' to match development machine"
echo "   - Restarts automatically on failure"
echo ""
echo "⚠️  Important notes:"
echo "   - This solves CycloneDDS interface switching crashes"
echo "   - Robot can now safely switch between wlan0/wlan1/eth0"
echo "   - Service starts after Tailscale is ready"
echo ""
echo "🎯 Next steps:"
echo "   1. Start the service: sudo systemctl start zenoh-bridge-dds"
echo "   2. Test with: /unitree/zenoh/test_bridge.sh"
echo "   3. Set up development machine with setup_dev_machine.sh"
echo "   4. Test DDS communication from your dev machine" 