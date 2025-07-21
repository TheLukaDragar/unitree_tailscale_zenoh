#!/bin/bash
# Test script to verify zenoh-bridge-dds is working on Go2

echo "🤖 Testing zenoh-bridge-dds on Go2 robot"
echo "=========================================="

# Check service status
echo "📋 Service Status:"
systemctl is-active zenoh-bridge-dds && echo "✅ Service is running" || echo "❌ Service is not running"

# Check REST API
echo ""
echo "🌐 REST API Test:"
if curl -s "http://localhost:8000/@/*/dds/version" > /dev/null; then
    VERSION=$(curl -s "http://localhost:8000/@/*/dds/version" | jq -r '.[0].value' 2>/dev/null)
    echo "✅ REST API accessible - Bridge version: $VERSION"
else
    echo "❌ REST API not accessible"
fi

# Check routes
echo ""
echo "🔗 Active Routes:"
ROUTE_COUNT=$(curl -s "http://localhost:8000/@/*/dds/route/**" | jq length 2>/dev/null)
if [ "$ROUTE_COUNT" -gt 0 ]; then
    echo "✅ Found $ROUTE_COUNT active routes"
    echo "📡 Sample routes:"
    curl -s "http://localhost:8000/@/*/dds/route/**" | jq -r '.[0:5][].key' | sed 's/.*route\///g' | head -5
else
    echo "❌ No routes found"
fi

# Network info
echo ""
echo "📡 Network Information:"
echo "Listening on: tcp/$(ip addr show wlan0 | grep 'inet ' | awk '{print $2}' | cut -d/ -f1):7447"
echo "Tailscale IP: $(tailscale ip -4 2>/dev/null || echo 'Not available')"

# Summary
echo ""
echo "🎯 Quick Tests from Development Machine:"
echo "1. Test connection: curl http://100.92.165.120:8000/@/*/dds/version"
echo "2. List routes: curl http://100.92.165.120:8000/@/*/dds/route/**"
echo "3. Monitor robot data: curl http://100.92.165.120:8000/go2/rt/lowstate"
echo ""
echo "For development machine setup:"
echo "scp root@100.92.165.120:/unitree/zenoh/setup_dev_machine.sh ~/setup_zenoh.sh"
echo "chmod +x ~/setup_zenoh.sh && ~/setup_zenoh.sh" 