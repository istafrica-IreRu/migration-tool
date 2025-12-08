import { useEffect, useRef, useState } from 'react';
import { io, Socket } from 'socket.io-client';
import { ProgressUpdate, ErrorUpdate, CompleteUpdate } from '@/lib/api';

interface UseWebSocketReturn {
  isConnected: boolean;
  lastProgress: ProgressUpdate | null;
  lastError: ErrorUpdate | null;
  lastComplete: CompleteUpdate | null;
  connectionError: string | null;
}

const WS_URL = process.env.NODE_ENV === 'production' ? '' : 'http://localhost:5000';

export const useWebSocket = (): UseWebSocketReturn => {
  const [isConnected, setIsConnected] = useState(false);
  const [lastProgress, setLastProgress] = useState<ProgressUpdate | null>(null);
  const [lastError, setLastError] = useState<ErrorUpdate | null>(null);
  const [lastComplete, setLastComplete] = useState<CompleteUpdate | null>(null);
  const [connectionError, setConnectionError] = useState<string | null>(null);
  const socketRef = useRef<Socket | null>(null);

  useEffect(() => {
    // Initialize socket connection
    socketRef.current = io(WS_URL, {
      transports: ['polling', 'websocket'],
      timeout: 20000,
      forceNew: true,
      reconnection: true,
      reconnectionDelay: 1000,
      reconnectionAttempts: 5,
    });

    const socket = socketRef.current;

    // Connection event handlers
    socket.on('connect', () => {
      console.log('Connected to WebSocket server');
      setIsConnected(true);
      setConnectionError(null);
    });

    socket.on('disconnect', () => {
      console.log('Disconnected from WebSocket server');
      setIsConnected(false);
    });

    socket.on('connect_error', (error) => {
      console.error('WebSocket connection error:', error);
      setConnectionError(error.message);
      setIsConnected(false);
    });

    // Migration event handlers
    socket.on('progress', (data: ProgressUpdate) => {
      console.log('Progress update:', data);
      setLastProgress(data);
    });

    socket.on('error', (data: ErrorUpdate) => {
      console.error('Migration error:', data);
      setLastError(data);
    });

    socket.on('complete', (data: CompleteUpdate) => {
      console.log('Migration complete:', data);
      setLastComplete(data);
    });

    socket.on('connected', (data) => {
      console.log('Server acknowledgment:', data);
    });

    // Cleanup on unmount
    return () => {
      if (socketRef.current) {
        socketRef.current.disconnect();
      }
    };
  }, []);

  return {
    isConnected,
    lastProgress,
    lastError,
    lastComplete,
    connectionError,
  };
};
