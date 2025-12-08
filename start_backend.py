#!/usr/bin/env python3
"""
Start the WinSchool Migration Backend Server
Usage: python start_backend.py
"""
import sys
import os

# Add src directory to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'src'))

if __name__ == '__main__':
    print("=" * 60)
    print("🚀 WinSchool Migration Backend Server")
    print("=" * 60)
    print("🌐 Starting server on http://localhost:5000")
    print("📊 API endpoints available at /api/*")
    print("🔌 WebSocket server for real-time updates")
    print("=" * 60)
    print("💡 Start the frontend with:")
    print("   cd frontend-lovable && npm run dev")
    print("=" * 60)
    
    # Import and run the Flask app
    from api import app, socketio
    socketio.run(app, host='0.0.0.0', port=5000, debug=True)
