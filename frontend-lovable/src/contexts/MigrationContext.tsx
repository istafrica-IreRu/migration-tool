import React, { createContext, useContext, useState, useEffect, ReactNode } from 'react';

export interface HistoryEntry {
    id: string;
    timestamp: string;
    type: 'migration' | 'normalization' | 'connection';
    description: string;
    status: 'success' | 'error' | 'running';
    details?: string;
}

export interface ConnectionInfo {
    mssql?: string;
    postgresql?: string;
    lastConnected?: string;
}

export interface FullConnectionSettings {
    mssql: any;
    postgresql: any;
}

interface MigrationContextType {
    history: HistoryEntry[];
    connectionInfo: ConnectionInfo;
    fullSettings: FullConnectionSettings | null;
    addHistoryEntry: (entry: Omit<HistoryEntry, 'id' | 'timestamp'>) => void;
    updateConnectionInfo: (info: ConnectionInfo) => void;
    updateFullSettings: (settings: FullConnectionSettings) => void;
    clearHistory: () => void;
}

const MigrationContext = createContext<MigrationContextType | undefined>(undefined);

export const MigrationProvider = ({ children }: { children: ReactNode }) => {
    const [history, setHistory] = useState<HistoryEntry[]>([]);
    const [connectionInfo, setConnectionInfo] = useState<ConnectionInfo>({});
    const [fullSettings, setFullSettings] = useState<FullConnectionSettings | null>(null);

    // Load history from localStorage on mount
    useEffect(() => {
        const savedHistory = localStorage.getItem('migration_history');
        if (savedHistory) {
            try {
                setHistory(JSON.parse(savedHistory));
            } catch (e) {
                console.error('Failed to parse history from localStorage', e);
            }
        }

        const savedConnection = localStorage.getItem('connection_info');
        if (savedConnection) {
            try {
                setConnectionInfo(JSON.parse(savedConnection));
            } catch (e) {
                console.error('Failed to parse connection info from localStorage', e);
            }
        }

        const savedFullSettings = localStorage.getItem('full_connection_settings');
        if (savedFullSettings) {
            try {
                setFullSettings(JSON.parse(savedFullSettings));
            } catch (e) {
                console.error('Failed to parse full settings from localStorage', e);
            }
        }
    }, []);

    // Persist history to localStorage whenever it changes
    useEffect(() => {
        localStorage.setItem('migration_history', JSON.stringify(history));
    }, [history]);

    // Persist connection info to localStorage whenever it changes
    useEffect(() => {
        localStorage.setItem('connection_info', JSON.stringify(connectionInfo));
    }, [connectionInfo]);

    // Persist full settings to localStorage whenever it changes
    useEffect(() => {
        if (fullSettings) {
            localStorage.setItem('full_connection_settings', JSON.stringify(fullSettings));
        }
    }, [fullSettings]);

    const addHistoryEntry = (entry: Omit<HistoryEntry, 'id' | 'timestamp'>) => {
        const newEntry: HistoryEntry = {
            ...entry,
            id: Math.random().toString(36).substr(2, 9),
            timestamp: new Date().toISOString(),
        };
        setHistory((prev) => [newEntry, ...prev].slice(0, 100)); // Keep last 100 entries
    };

    const updateConnectionInfo = (info: ConnectionInfo) => {
        setConnectionInfo((prev) => ({ ...prev, ...info, lastConnected: new Date().toISOString() }));
    };

    const updateFullSettings = (settings: FullConnectionSettings) => {
        setFullSettings(settings);
    };

    const clearHistory = () => {
        setHistory([]);
        localStorage.removeItem('migration_history');
    };

    return (
        <MigrationContext.Provider
            value={{
                history,
                connectionInfo,
                fullSettings,
                addHistoryEntry,
                updateConnectionInfo,
                updateFullSettings,
                clearHistory,
            }}
        >
            {children}
        </MigrationContext.Provider>
    );
};

export const useMigration = () => {
    const context = useContext(MigrationContext);
    if (context === undefined) {
        throw new Error('useMigration must be used within a MigrationProvider');
    }
    return context;
};
