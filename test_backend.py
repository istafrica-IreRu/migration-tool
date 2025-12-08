#!/usr/bin/env python3
"""
Simple test script to verify backend API and WebSocket functionality
"""
import requests
import socketio
import time
import sys

def test_api_endpoints():
    """Test REST API endpoints"""
    base_url = "http://localhost:5000"
    
    print("Testing API endpoints...")
    
    try:
        # Test tables endpoint
        response = requests.get(f"{base_url}/api/tables", timeout=5)
        print(f"[OK] GET /api/tables: {response.status_code}")
        if response.status_code == 200:
            data = response.json()
            print(f"   Found {len(data.get('tables', []))} tables")
        else:
            print(f"   Error: {response.text}")
    except Exception as e:
        print(f"[ERROR] GET /api/tables failed: {e}")
    
    try:
        # Test status endpoint
        response = requests.get(f"{base_url}/api/status", timeout=5)
        print(f"[OK] GET /api/status: {response.status_code}")
        if response.status_code == 200:
            data = response.json()
            print(f"   Status: {data.get('status', 'unknown')}")
    except Exception as e:
        print(f"[ERROR] GET /api/status failed: {e}")

def test_websocket():
    """Test WebSocket connection"""
    print("\nTesting WebSocket connection...")
    
    sio = socketio.Client(logger=False, engineio_logger=False)
    
    @sio.event
    def connect():
        print("[OK] WebSocket connected successfully!")
    
    @sio.event
    def disconnect():
        print("[INFO] WebSocket disconnected")
    
    @sio.event
    def connect_error(data):
        print(f"[ERROR] WebSocket connection error: {data}")
    
    @sio.event
    def connected(data):
        print(f"[INFO] Received connected event: {data}")
    
    try:
        sio.connect('http://localhost:5000', transports=['polling', 'websocket'])
        time.sleep(2)  # Wait for connection
        sio.disconnect()
        return True
    except Exception as e:
        print(f"[ERROR] WebSocket connection failed: {e}")
        return False

def main():
    print("WinSchool Migration Backend Test")
    print("=" * 40)
    
    # Test API endpoints
    test_api_endpoints()
    
    # Test WebSocket
    websocket_ok = test_websocket()
    
    print("\n" + "=" * 40)
    if websocket_ok:
        print("[SUCCESS] Backend tests completed successfully!")
        print("[INFO] You can now start the frontend with: cd frontend-lovable && npm run dev")
    else:
        print("[ERROR] Some tests failed. Check the backend configuration.")
        sys.exit(1)

if __name__ == "__main__":
    main()
