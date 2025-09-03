#!/bin/bash

# Vaadly Web Server Script
# This script serves the Flutter web app locally

echo "🚀 Starting Vaadly Web Server..."
echo "📱 Your app will be available at: http://localhost:8000"
echo "🌐 You can access it from any device on your network"
echo ""

# Check if web build exists
if [ ! -d "build/web" ]; then
    echo "❌ Web build not found. Building web version first..."
    flutter build web
    if [ $? -ne 0 ]; then
        echo "❌ Failed to build web version"
        exit 1
    fi
    echo "✅ Web build completed"
fi

# Start web server
echo "🌐 Starting server on port 8000..."
echo "📱 Open http://localhost:8000 in your browser"
echo "🔄 Press Ctrl+C to stop the server"
echo ""

cd build/web
python3 -m http.server 8000
