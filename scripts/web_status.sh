#!/bin/bash

# Vaadly Web Server Status Script

echo "🌐 Vaadly Web Server Status"
echo "=========================="

# Check if web server is running
if lsof -i :8000 > /dev/null 2>&1; then
    echo "✅ Web server is RUNNING on port 8000"
    echo "📱 Local access: http://localhost:8000"
    echo "🌍 Network access: http://192.168.1.130:8000"
    echo ""
    echo "🔍 Server details:"
    lsof -i :8000
else
    echo "❌ Web server is NOT running on port 8000"
    echo ""
    echo "🚀 To start the server:"
    echo "   ./scripts/serve_web.sh"
fi

echo ""
echo "🔧 Available scripts:"
echo "   ./scripts/serve_web.sh     - Start production web server"
echo "   ./scripts/dev_web.sh       - Start development server"
echo "   ./scripts/web_status.sh    - Check server status (this script)"
echo ""
echo "📚 For more info, see: WEB_TESTING.md"
