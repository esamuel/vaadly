#!/bin/bash

echo "🚀 Vaadly Setup Script"
echo "========================"

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter not found. Please install Flutter first."
    exit 1
fi

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI not found. Installing..."
    npm install -g firebase-tools
fi

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "❌ Node.js not found. Please install Node.js 20+ first."
    exit 1
fi

echo "✅ Prerequisites check passed"

# Create .env file from template
if [ ! -f .env ]; then
    echo "📝 Creating .env file from template..."
    cp env_template.txt .env
    echo "⚠️  Please edit .env file with your actual API keys and configuration"
else
    echo "✅ .env file already exists"
fi

# Install Flutter dependencies
echo "📦 Installing Flutter dependencies..."
flutter pub get

# Install Cloud Functions dependencies
echo "🔧 Installing Cloud Functions dependencies..."
cd functions
npm install
cd ..

echo ""
echo "🎉 Setup completed!"
echo ""
echo "Next steps:"
echo "1. Edit .env file with your API keys"
echo "2. Run 'firebase login' to authenticate"
echo "3. Run 'firebase init' to configure your project"
echo "4. Run 'flutterfire configure' to set up Flutter Firebase"
echo "5. Deploy Cloud Functions: cd functions && npm run build && firebase deploy --only functions"
echo "6. Deploy security rules: firebase deploy --only firestore:rules,firestore:indexes,storage"
echo "7. Run the app: flutter run"
echo ""
echo "For detailed instructions, see README.md"
