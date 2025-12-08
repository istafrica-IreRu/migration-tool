"""
Flask API for migration frontend.
Provides endpoints for table listing, migration status, and starting migrations.
"""
import os
import sys
import json
import logging
import threading
from typing import Dict, List, Optional
from flask import Flask, jsonify, request, send_from_directory
from flask_cors import CORS
from flask_socketio import SocketIO, emit
import pyodbc
import psycopg2
from psycopg2 import extras

# Import migration functions from main.py
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import main as migration_main
from main import (
    get_pg_connection, get_mssql_metadata,
    translate_identifier, topological_sort, migrate_schemas,
    migrate_tables_structure, migrate_data, migrate_constraints_and_indexes,
    migrate_views, load_translation_dict
)
from column_additions import add_new_columns_to_tables

# Import config
from config import load_config

# Get constants from main module
SCHEMAS_TO_MIGRATE = migration_main.SCHEMAS_TO_MIGRATE

app = Flask(__name__, static_folder='../frontend/build', static_url_path='')
CORS(app, origins=["http://localhost:5200", "http://127.0.0.1:5200"])
socketio = SocketIO(
    app, 
    cors_allowed_origins=["http://localhost:5200", "http://127.0.0.1:5200"],
    async_mode='threading',
    logger=True,
    engineio_logger=True
)

# Global state
migration_state = {
    'status': 'idle',  # idle, running, completed, error
    'progress': 0,
    'current_phase': '',
    'current_table': '',
    'tables_total': 0,
    'tables_completed': 0,
    'message': '',
    'error': None,
    'selected_tables': [],
    'available_tables': []
}

migration_thread: Optional[threading.Thread] = None
TRANSLATION_DICT: Dict[str, str] = {}


def get_configured_mssql_connection():
    """Get MSSQL connection using config."""
    try:
        config = load_config()
        return pyodbc.connect(config.mssql.get_connection_string())
    except Exception as e:
        logging.error(f"Error connecting to MSSQL via config: {e}")
        # Fallback to main.py's function if config fails (though it likely won't work if trusted auth is needed)
        from main import get_mssql_connection
        return get_mssql_connection()


def emit_progress(phase: str, message: str, progress: int = None, table: str = None):
    """Emit progress update via WebSocket."""
    if progress is not None:
        migration_state['progress'] = progress
    if table:
        migration_state['current_table'] = table
    migration_state['current_phase'] = phase
    migration_state['message'] = message
    
    socketio.emit('progress', {
        'phase': phase,
        'message': message,
        'progress': migration_state['progress'],
        'current_table': table or migration_state['current_table'],
        'tables_total': migration_state['tables_total'],
        'tables_completed': migration_state['tables_completed']
    })


def emit_error(error: str):
    """Emit error via WebSocket."""
    migration_state['status'] = 'error'
    migration_state['error'] = error
    socketio.emit('error', {'error': error})


def emit_complete():
    """Emit completion via WebSocket."""
    migration_state['status'] = 'completed'
    migration_state['progress'] = 100
    socketio.emit('complete', {'message': 'Migration completed successfully!'})


class MigrationLogger:
    """Custom logger that emits to WebSocket."""
    
    def __init__(self, original_logger):
        self.original_logger = original_logger
    
    def info(self, message: str):
        self.original_logger.info(message)
        if 'Phase' in message or 'migrating' in message.lower() or 'complete' in message.lower():
            emit_progress(migration_state['current_phase'], message)
    
    def error(self, message: str):
        self.original_logger.error(message)
        emit_error(message)
    
    def warning(self, message: str):
        self.original_logger.warning(message)
        emit_progress(migration_state['current_phase'], f"Warning: {message}")


def run_migration(selected_tables: List[str], translations_file: str, normalize: bool = False):
    """Run migration in a separate thread."""
    global migration_state, TRANSLATION_DICT
    
    # Import main module functions
    import main as migration_main
    
    try:
        migration_state['status'] = 'running'
        migration_state['progress'] = 0
        migration_state['error'] = None
        migration_state['selected_tables'] = selected_tables
        
        # Load config and update main module globals
        config = load_config()
        migration_main.MSSQL_SERVER = config.mssql.server
        migration_main.MSSQL_DATABASE = config.mssql.database
        migration_main.MSSQL_USERNAME = config.mssql.username
        migration_main.MSSQL_PASSWORD = config.mssql.password
        migration_main.PG_HOST = config.postgresql.host
        migration_main.PG_DATABASE = config.postgresql.database
        migration_main.PG_USER = config.postgresql.user
        migration_main.PG_PASSWORD = config.postgresql.password
        migration_main.PG_PORT = config.postgresql.port
        migration_main.SCHEMAS_TO_MIGRATE = config.migration.schemas_to_migrate
        
        # Set global translation dict in main module
        migration_main.TRANSLATION_DICT = load_translation_dict(translations_file)
        TRANSLATION_DICT = migration_main.TRANSLATION_DICT
        
        # Update translate_identifier to use the loaded dict
        # The function in main.py uses the global TRANSLATION_DICT, so we just need to set it
        
        # Connect to databases
        emit_progress('connecting', 'Connecting to databases...', 5)
        mssql_conn = get_configured_mssql_connection()
        pg_conn = get_pg_connection()
        pg_conn.autocommit = True
        pg_cursor = pg_conn.cursor()
        
        # Get metadata
        emit_progress('fetching', 'Fetching MSSQL metadata...', 10)
        mssql_cursor = mssql_conn.cursor()
        metadata = get_mssql_metadata(mssql_cursor)
        
        # Filter tables if specified
        if selected_tables:
            translated_tables_to_migrate = []
            for table_ref in selected_tables:
                if '.' not in table_ref:
                    continue
                schema, table = table_ref.split('.', 1)
                # Use translate_identifier from main module
                translated_table = migration_main.translate_identifier(table)
                translated_tables_to_migrate.append(f"{schema}.{translated_table}")
            
            tables_to_keep = {t for t in metadata['tables'] if t in translated_tables_to_migrate}
            metadata['tables'] = {k: v for k, v in metadata['tables'].items() if k in tables_to_keep}
            migratable_tables = list(tables_to_keep)
        else:
            migratable_tables = list(metadata['tables'].keys())
        
        migration_state['tables_total'] = len(migratable_tables)
        migration_state['tables_completed'] = 0
        
        if not migratable_tables:
            emit_error("No tables found to migrate")
            return
        
        sorted_tables = topological_sort(metadata['dependencies'], migratable_tables)
        
        # Phase 1: Schemas
        emit_progress('schemas', 'Migrating schemas...', 15)
        migrate_schemas(pg_cursor, metadata['schemas'])
        
        # Phase 2: Table structures
        emit_progress('structures', 'Creating table structures...', 25)
        migrate_tables_structure(pg_cursor, metadata['tables'])
        
        # Phase 3: Data migration with progress tracking
        emit_progress('data', 'Migrating data...', 35)
        pg_conn.autocommit = False
        
        for idx, table_key in enumerate(sorted_tables):
            if table_key not in metadata['tables']:
                continue
            
            migration_state['tables_completed'] = idx
            progress = 35 + int((idx / len(sorted_tables)) * 50)
            emit_progress('data', f'Migrating table: {table_key}', progress, table_key)
            
            schema_name, table_name = table_key.split('.')
            table_data = metadata['tables'][table_key]
            original_schema = table_data['columns'][0].TABLE_SCHEMA
            original_table = table_data['columns'][0].TABLE_NAME
            pg_table_key = f'"{schema_name}"."{table_name}"' if schema_name != 'dbo' else f'public."{table_name}"'
            
            # Get columns - use the same logic as in main.py
            original_columns = []
            final_translated_columns = []
            used_column_names = set()
            
            for col in table_data['columns']:
                original_column = col.COLUMN_NAME
                # Use translate_identifier from main module which uses the global TRANSLATION_DICT
                base_translated_name = migration_main.translate_identifier(original_column)
                final_translated_name = base_translated_name
                
                counter = 1
                while final_translated_name.lower() in used_column_names:
                    final_translated_name = f"{base_translated_name}_{counter}"
                    counter += 1
                
                used_column_names.add(final_translated_name.lower())
                original_columns.append(original_column)
                final_translated_columns.append(final_translated_name)
            
            select_columns = ', '.join([f'[{col}]' for col in original_columns])
            mssql_cursor.execute(f'SELECT {select_columns} FROM "{original_schema}"."{original_table}"')
            
            insert_columns = ', '.join([f'"{col}"' for col in final_translated_columns])
            insert_sql = f'INSERT INTO {pg_table_key} ({insert_columns}) VALUES %s'
            
            page_size = 1000
            rows_migrated = 0
            while True:
                rows = mssql_cursor.fetchmany(page_size)
                if not rows:
                    break
                
                cleaned_rows = []
                for row in rows:
                    cleaned_row = tuple(
                        item.replace('\x00', '') if isinstance(item, str) else item
                        for item in row
                    )
                    cleaned_rows.append(cleaned_row)
                
                if cleaned_rows:
                    extras.execute_values(pg_cursor, insert_sql, cleaned_rows, page_size=page_size)
                    rows_migrated += len(cleaned_rows)
            
            pg_conn.commit()
            migration_state['tables_completed'] = idx + 1
        
        # Phase 3.5: Add new columns
        emit_progress('columns', 'Adding new columns to migrated tables...', 80)
        try:
            add_new_columns_to_tables(pg_cursor)
            pg_conn.commit()  # Commit changes before switching autocommit
            emit_progress('columns', 'New columns added successfully', 82)
        except Exception as e:
            logger.error(f"Error adding new columns: {e}", exc_info=True)
            emit_progress('columns', f'Warning: Column addition had errors - {str(e)}', 82)
            # Don't fail the entire migration if column addition fails
            pg_conn.rollback()

        # Phase 4: Constraints and indexes
        emit_progress('constraints', 'Adding constraints and indexes...', 85)
        pg_conn.autocommit = True
        migrate_constraints_and_indexes(pg_cursor, metadata['tables'])
        
        # Phase 5: Views
        emit_progress('views', 'Migrating views...', 90)
        migrate_views(pg_cursor, metadata['views'], metadata['tables'])
        
        # Phase 6: Normalization (if requested)
        if normalize:
            emit_progress('normalize', 'Running normalization scripts...', 95)
            # pg_conn.autocommit = False
            # execute_normalization_scripts(pg_cursor, pg_conn, 'reference')
            # pg_conn.autocommit = True
            logging.warning("Normalization via frontend is currently disabled.")
        
        # Cleanup
        mssql_conn.close()
        pg_conn.close()
        
        emit_complete()
        
    except Exception as e:
        logging.error(f"Migration error: {e}", exc_info=True)
        emit_error(str(e))
    finally:
        migration_state['status'] = 'idle' if migration_state['status'] != 'error' else 'error'


@app.route('/api/tables', methods=['GET'])
def get_tables():
    """Get list of available tables from MSSQL."""
    try:
        mssql_conn = get_configured_mssql_connection()
        mssql_cursor = mssql_conn.cursor()
        
        # Get tables from specified schemas
        # Load config to get schemas if not already set
        config = load_config()
        schemas = config.migration.schemas_to_migrate
        
        schemas_filter = ", ".join([f"'{s}'" for s in schemas])
        query = f"""
        SELECT TABLE_SCHEMA, TABLE_NAME
        FROM INFORMATION_SCHEMA.TABLES
        WHERE TABLE_TYPE = 'BASE TABLE' AND TABLE_SCHEMA IN ({schemas_filter})
        ORDER BY TABLE_SCHEMA, TABLE_NAME
        """
        mssql_cursor.execute(query)
        
        tables = []
        for row in mssql_cursor.fetchall():
            tables.append({
                'schema': row.TABLE_SCHEMA,
                'name': row.TABLE_NAME,
                'key': f"{row.TABLE_SCHEMA}.{row.TABLE_NAME}"
            })
        
        mssql_conn.close()
        migration_state['available_tables'] = tables
        
        return jsonify({'tables': tables})
    except Exception as e:
        logging.error(f"Error fetching tables: {e}")
        return jsonify({'error': str(e)}), 500


@app.route('/api/status', methods=['GET'])
def get_status():
    """Get current migration status."""
    return jsonify(migration_state)


@app.route('/api/migrate', methods=['POST'])
def start_migration():
    """Start migration with selected tables."""
    global migration_thread
    
    if migration_state['status'] == 'running':
        return jsonify({'error': 'Migration already in progress'}), 400
    
    data = request.json
    selected_tables = data.get('tables', [])
    translations_file = data.get('translations_file', 'resources/translations.json')
    normalize = data.get('normalize', False)
    
    if not os.path.exists(translations_file):
        return jsonify({'error': f'Translations file not found: {translations_file}'}), 400
    
    # Reset state
    migration_state['status'] = 'running'
    migration_state['progress'] = 0
    migration_state['error'] = None
    migration_state['tables_completed'] = 0
    
    # Start migration in background thread
    migration_thread = threading.Thread(
        target=run_migration,
        args=(selected_tables, translations_file, normalize),
        daemon=True
    )
    migration_thread.start()
    
    return jsonify({'message': 'Migration started', 'status': 'running'})


@app.route('/api/stop', methods=['POST'])
def stop_migration():
    """Stop current migration (if running)."""
    # Note: This is a simple implementation. In production, you'd want proper thread cancellation.
    if migration_state['status'] == 'running':
        migration_state['status'] = 'stopped'
        migration_state['message'] = 'Migration stopped by user'
        return jsonify({'message': 'Migration stop requested'})
    return jsonify({'message': 'No migration in progress'}), 400


@app.route('/api/normalize', methods=['POST'])
def run_normalization():
    """Run normalization migration scripts."""
    global migration_thread
    
    if migration_state['status'] == 'running':
        return jsonify({'error': 'Migration already in progress'}), 400
    
    data = request.json
    migration_types = data.get('migration_types', [])
    
    # Support both single string (legacy) and array
    if isinstance(migration_types, str):
        migration_types = [migration_types]
    
    if not migration_types:
        return jsonify({'error': 'No migration types specified'}), 400
    
    # Map migration types to SQL files
    migration_files = {
        'users': 'reference/V000__create_normalized_users_table.sql',
        'enrollment': 'reference/V001__create_normalized_enrollment_tables.sql',
        'guardians': 'reference/V002__create_normalized_guardian_tables.sql',
        'academic': 'reference/V003__create_normalized_academic_tables.sql'
    }
    
    # Validate all migration types
    invalid_types = [mt for mt in migration_types if mt not in migration_files]
    if invalid_types:
        return jsonify({'error': f'Invalid migration type(s): {", ".join(invalid_types)}'}), 400
    
    # Check all files exist
    missing_files = []
    for migration_type in migration_types:
        sql_file = migration_files[migration_type]
        if not os.path.exists(sql_file):
            missing_files.append(sql_file)
    
    if missing_files:
        return jsonify({'error': f'Migration file(s) not found: {", ".join(missing_files)}'}), 404
    
    # Reset state
    migration_state['status'] = 'running'
    migration_state['progress'] = 0
    migration_state['error'] = None
    migration_state['current_phase'] = f'Migrating {len(migration_types)} module(s)'
    
    # Start normalization in background thread
    migration_thread = threading.Thread(
        target=run_normalization_scripts,
        args=(migration_types, migration_files),
        daemon=True
    )
    migration_thread.start()
    
    return jsonify({'message': f'Migration started for {len(migration_types)} module(s)', 'status': 'running'})


def run_normalization_scripts(migration_types: List[str], migration_files: Dict[str, str]):
    """Execute multiple normalization SQL scripts sequentially."""
    try:
        migration_state['status'] = 'running'
        migration_state['progress'] = 0
        migration_state['error'] = None
        
        total_modules = len(migration_types)
        
        emit_progress('connecting', f'Connecting to PostgreSQL for {total_modules} module migration(s)...', 5)
        
        # Connect to PostgreSQL
        pg_conn = get_pg_connection()
        pg_cursor = pg_conn.cursor()
        
        # Execute each migration script sequentially
        for idx, migration_type in enumerate(migration_types):
            sql_file = migration_files[migration_type]
            
            # Calculate progress for this module
            base_progress = int((idx / total_modules) * 90) + 5
            module_progress_range = int(90 / total_modules)
            
            emit_progress(
                'reading', 
                f'Module {idx + 1}/{total_modules}: Reading {migration_type} migration script...', 
                base_progress
            )
            
            # Read SQL file
            with open(sql_file, 'r', encoding='utf-8') as f:
                sql_content = f.read()
            
            emit_progress(
                'executing', 
                f'Module {idx + 1}/{total_modules}: Executing {migration_type} migration...', 
                base_progress + int(module_progress_range * 0.3)
            )
            
            # Execute SQL script
            try:
                pg_cursor.execute(sql_content)
                pg_conn.commit()
                emit_progress(
                    'complete', 
                    f'Module {idx + 1}/{total_modules}: {migration_type.capitalize()} migration completed!', 
                    base_progress + module_progress_range
                )
            except Exception as e:
                pg_conn.rollback()
                raise Exception(f'SQL execution error in {migration_type} module: {str(e)}')
        
        # Cleanup
        pg_cursor.close()
        pg_conn.close()
        
        emit_progress('complete', f'All {total_modules} module(s) migrated successfully!', 100)
        emit_complete()
        
    except Exception as e:
        logging.error(f"Migration error: {e}", exc_info=True)
        emit_error(str(e))
    finally:
        migration_state['status'] = 'idle' if migration_state['status'] != 'error' else 'error'


@app.route('/')
def serve_frontend():
    """Serve the frontend application."""
    return send_from_directory(app.static_folder, 'index.html')


@socketio.on('connect')
def handle_connect():
    """Handle WebSocket connection."""
    emit('connected', {'message': 'Connected to migration server'})


if __name__ == '__main__':
    logging.basicConfig(level=logging.INFO)
    socketio.run(app, host='0.0.0.0', port=5000, debug=True)

