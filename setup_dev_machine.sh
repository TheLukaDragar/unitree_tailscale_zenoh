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
if command -v wget >/dev/null 2>&1; then
    wget "https://download.eclipse.org/zenoh/zenoh-plugin-dds/latest/zenoh-plugin-dds-1.4.0-x86_64-apple-darwin-standalone.zip"
elif command -v curl >/dev/null 2>&1; then
    curl -L -o "zenoh-plugin-dds-1.4.0-x86_64-apple-darwin-standalone.zip" "https://download.eclipse.org/zenoh/zenoh-plugin-dds/latest/zenoh-plugin-dds-1.4.0-x86_64-apple-darwin-standalone.zip"
else
    echo "❌ Neither wget nor curl found. Please install Homebrew and run: brew install wget"
    exit 1
fi

# Extract
echo "📦 Extracting..."
unzip -o "zenoh-plugin-dds-1.4.0-x86_64-apple-darwin-standalone.zip"
chmod +x zenoh-bridge-dds

# Create development machine config
echo "⚙️ Creating configuration..."
cat > config.json5 << EOD
{
  mode: "peer",
  connect: {
    endpoints: [
      "tcp/$ROBOT_TAILSCALE_IP:7447"  // Connect to robot
    ]
  },
  listen: {
    endpoints: [
      "tcp/$DEV_TAILSCALE_IP:7447",
      "tcp/127.0.0.1:7447"
    ]
  },
  plugins: {
    dds: {
      domain: 0,
      scope: "dev",  // Different scope to avoid conflicts
      localhost_only: false
    },
    rest: {
      http_port: 8001  // Different port than robot
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
echo "Press Ctrl+C to stop"
./zenoh-bridge-dds -c config.json5
EOF

chmod +x start_bridge.sh

echo "✅ Development machine setup complete!"
echo ""
echo "🚀 To start the bridge:"
echo "   cd ~/zenoh && ./start_bridge.sh"
echo ""
echo "🌐 REST API will be available at: http://localhost:8001"
echo "🔗 Robot connection: tcp/$ROBOT_TAILSCALE_IP:7447"
echo "🔗 Alternative connection (if on same network): tcp/10.106.5.64:7447"
echo ""
echo "📋 Quick tests:"
echo "   curl http://localhost:8001/@/*/dds/version"
echo "   curl http://localhost:8001/@/*/dds/route/**"
echo ""
echo "🤖 Robot data will be available with 'go2/' prefix:"
echo "   curl http://localhost:8001/go2/rt/lowstate" 