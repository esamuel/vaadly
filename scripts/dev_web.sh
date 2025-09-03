#!/bin/bash

# Vaadly Development Web Server Script
# This script runs the Flutter web app in development mode with hot reload

echo "🚀 Starting Vaadly Development Web Server..."
echo "📱 Your app will be available at: http://localhost:8080"
echo "🌐 You can access it from any device on your network"
echo "🔄 Changes will automatically reload"
echo ""

# Check if Flutter is available
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter not found. Please install Flutter first."
    exit 1
fi

# Start Flutter web in development mode
echo "🌐 Starting development server on port 8080..."
echo "📱 Open http://localhost:8080 in your browser"
echo "🔄 Press Ctrl+C to stop the server"
echo ""

flutter run -d web-server --web-port 8080 --web-hostname 0.0.0.0
