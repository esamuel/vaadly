#!/usr/bin/env bash
set -euo pipefail

# Deploy the Flutter web app to Firebase Hosting (vaadly-project)

echo "🔍 Checking Flutter SDK..."
flutter --version >/dev/null 2>&1 || { echo "Flutter not found in PATH"; exit 1; }

echo "📦 Getting dependencies..."
flutter pub get

echo "🧪 Analyzing (non-blocking)..."
flutter analyze || true

echo "🏗️  Building web (release)..."
flutter build web --release

echo "🚀 Deploying to Firebase Hosting (vaadly-project)..."
firebase deploy --only hosting --project vaadly-project

echo "✅ Deployed: https://vaadly-project.web.app"

