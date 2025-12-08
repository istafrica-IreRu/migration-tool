#!/bin/bash

# WinSchool Migration Tool - Frontend Startup Script

echo "🚀 Starting WinSchool Migration Tool Frontend..."

# Check if node_modules exists
if [ ! -d "node_modules" ]; then
    echo "📦 Installing dependencies..."
    npm install
fi

# Start the development server
echo "🌐 Starting development server on http://localhost:8080"
echo "🔗 Backend should be running on http://localhost:5000"
echo ""
echo "Press Ctrl+C to stop the server"

npm run dev
