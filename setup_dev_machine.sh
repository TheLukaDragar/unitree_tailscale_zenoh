#!/bin/bash
# Run this script on your development machine (Mac)

echo "🍎 Setting up zenoh-bridge-dds on macOS development machine..."

# Get this machine's Tailscale IP
if command -v tailscale >/dev/null 2>&1; then
    DEV_TAILSCALE_IP=$(tailscale ip -4)
    echo "Development machine Tailscale IP: $DEV_TAILSCALE_IP"
else
    echo "⚠️  Tailscale not found. Install from: https://tailscale.com/download/mac"
    echo "Using local IP instead..."
    DEV_TAILSCALE_IP=$(ifconfig | grep "inet " | grep -v 127.0.0.1 | head -1 | awk '{print $2}')
    echo "Development machine IP: $DEV_TAILSCALE_IP"
fi

ROBOT_TAILSCALE_IP="100.92.165.120"  # Go2 robot Tailscale IP

echo "Robot Tailscale IP: $ROBOT_TAILSCALE_IP"

# Create directory
mkdir -p ~/zenoh
cd ~/zenoh

# Download for macOS (try both wget and curl)
echo "📥 Downloading zenoh-bridge-dds for macOS..."
LATEST_VERSION="1.4.0"
ZIP_FILE="zenoh-bridge-dds-${LATEST_VERSION}-x86_64-apple-darwin.zip"

if command -v wget >/dev/null 2>&1; then
    wget "https://download.eclipse.org/zenoh/zenoh-plugin-dds/latest/x86_64-apple-darwin/${ZIP_FILE}"
elif command -v curl >/dev/null 2>&1; then
    curl -L -o "${ZIP_FILE}" "https://download.eclipse.org/zenoh/zenoh-plugin-dds/latest/x86_64-apple-darwin/${ZIP_FILE}"
else
    echo "❌ Neither wget nor curl found. Please install Homebrew and run: brew install wget"
    exit 1
fi

# Extract
echo "📦 Extracting..."
unzip -o "${ZIP_FILE}"
chmod +x zenoh-bridge-dds

# Create development machine config that matches the robot
echo "⚙️ Creating configuration..."
cat > config.json5 << EOD
{
  "mode": "peer",
  "connect": {
    "endpoints": [
      "tcp/${ROBOT_TAILSCALE_IP}:7447"
    ]
  },
  "listen": {
    "endpoints": [
      "tcp/${DEV_TAILSCALE_IP}:7447",
      "tcp/127.0.0.1:7447"
    ]
  },
  "plugins": {
    "dds": {
      "domain": 0,
      "scope": "go2"
    },
    "rest": {
      "http_port": "8001"
    }
  }
}
EOD

# Create start script
cat > start_bridge.sh << 'EOF'
#!/bin/bash
echo "🚀 Starting zenoh-bridge-dds on development machine..."
echo "🔗 Connecting to Go2 robot via Tailscale..."
echo "🌐 REST API will be available at: http://localhost:8001"
echo "📋 Using scope: go2 (matches robot)"
echo ""
echo "Press Ctrl+C to stop"

# Use command line args instead of config file for reliability
./zenoh-bridge-dds \
  --mode peer \
  --connect tcp/100.92.165.120:7447 \
  --listen tcp/127.0.0.1:7447 \
  --domain 0 \
  --scope go2 \
  --rest-http-port 8001
EOF

chmod +x start_bridge.sh

# Create simple test script
cat > test_connection.sh << 'EOF'
#!/bin/bash
echo "🧪 Testing zenoh bridge connection..."
echo ""
echo "📊 Bridge status:"
curl -s http://localhost:8001/@/*/dds/version || echo "❌ Bridge not running"
echo ""
echo ""
echo "🔗 Active routes:"
curl -s 'http://localhost:8001/@/*/dds/route/**' | head -20
echo ""
echo ""
echo "🤖 Robot topics (should show go2 scope):"
curl -s 'http://localhost:8001/@/*/dds/route/**/rt/lowstate' | python3 -m json.tool 2>/dev/null || echo "No lowstate route found"
EOF

chmod +x test_connection.sh

echo "✅ Development machine setup complete!"
echo ""
echo "🚀 To start the bridge:"
echo "   cd ~/zenoh && ./start_bridge.sh"
echo ""
echo "🧪 To test the connection:"
echo "   cd ~/zenoh && ./test_connection.sh"
echo ""
echo "🌐 REST API will be available at: http://localhost:8001"
echo "🔗 Robot connection: tcp/${ROBOT_TAILSCALE_IP}:7447"
echo ""
echo "🎯 Key fixes made:"
echo "   ✅ Changed scope from 'dev' to 'go2' (matches robot)"
echo "   ✅ Fixed JSON5 syntax"
echo "   ✅ Corrected download URL"
echo "   ✅ Added test script"
echo ""
echo "📋 After starting, your DDS subscribers should receive data from:"
echo "   - rt/lowstate (robot telemetry)"
echo "   - rt/sportmodestate (sport mode)"
echo "   - rt/servicestate (service status)" 