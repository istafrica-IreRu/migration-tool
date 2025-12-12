/**
 * API service for WinSchool Migration Tool
 * Handles communication with the Flask backend
 */

export interface Table {
  key: string;
  schema: string;
  name: string;
}

export interface MigrationStatus {
  status: 'idle' | 'running' | 'completed' | 'error';
  progress: number;
  current_phase: string;
  current_table: string;
  tables_total: number;
  tables_completed: number;
  message: string;
  error: string | null;
  selected_tables: string[];
  available_tables: Table[];
}

export interface ProgressUpdate {
  phase: string;
  message: string;
  progress: number;
  current_table: string;
  tables_total: number;
  tables_completed: number;
}

export interface ErrorUpdate {
  error: string;
}

export interface CompleteUpdate {
  message: string;
}

const API_BASE_URL = process.env.NODE_ENV === 'production' ? '' : 'http://localhost:5000';

class ApiService {
  async fetchTables(): Promise<{ tables: Table[]; error?: string }> {
    try {
      const response = await fetch(`${API_BASE_URL}/api/tables`);
      const data = await response.json();

      if (!response.ok) {
        throw new Error(data.error || 'Failed to fetch tables');
      }

      return data;
    } catch (error) {
      console.error('Error fetching tables:', error);
      return {
        tables: [],
        error: error instanceof Error ? error.message : 'Unknown error'
      };
    }
  }

  async getStatus(): Promise<MigrationStatus> {
    try {
      const response = await fetch(`${API_BASE_URL}/api/status`);
      const data = await response.json();

      if (!response.ok) {
        throw new Error('Failed to fetch status');
      }

      return data;
    } catch (error) {
      console.error('Error fetching status:', error);
      throw error;
    }
  }

  async startMigration(
    selectedTables: string[],
    translationsFile: string = 'resources/translations.json',
    normalize: boolean = false
  ): Promise<{ message: string; status: string; error?: string }> {
    try {
      const response = await fetch(`${API_BASE_URL}/api/migrate`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          tables: selectedTables,
          translations_file: translationsFile,
          normalize,
        }),
      });

      const data = await response.json();

      if (!response.ok) {
        throw new Error(data.error || 'Failed to start migration');
      }

      return data;
    } catch (error) {
      console.error('Error starting migration:', error);
      return {
        message: '',
        status: 'error',
        error: error instanceof Error ? error.message : 'Unknown error'
      };
    }
  }

  async startNormalization(migrationTypes: string | string[]): Promise<{ message: string; status: string; error?: string }> {
    try {
      // Convert to array if single string
      const typesArray = Array.isArray(migrationTypes) ? migrationTypes : [migrationTypes];

      const response = await fetch(`${API_BASE_URL}/api/normalize`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          migration_types: typesArray,
        }),
      });

      const data = await response.json();

      if (!response.ok) {
        throw new Error(data.error || 'Failed to start module migration');
      }

      return data;
    } catch (error) {
      console.error('Error starting module migration:', error);
      return {
        message: '',
        status: 'error',
        error: error instanceof Error ? error.message : 'Unknown error'
      };
    }
  }

  async stopMigration(): Promise<{ message: string; error?: string }> {
    try {
      const response = await fetch(`${API_BASE_URL}/api/stop`, {
        method: 'POST',
      });

      const data = await response.json();

      if (!response.ok) {
        throw new Error(data.error || 'Failed to stop migration');
      }

      return data;
    } catch (error) {
      console.error('Error stopping migration:', error);
      return {
        message: '',
        error: error instanceof Error ? error.message : 'Unknown error'
      };
    }
  }
}

export const apiService = new ApiService();
