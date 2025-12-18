"""
Flask API for migration frontend.
Provides endpoints for table listing, migration status, and starting migrations.
"""
import os
import sys
import json
import logging
import threading
import re
from typing import Dict, List, Optional, Any, Tuple
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
runtime_config: Optional[Dict[str, Any]] = None


def get_configured_mssql_connection():
    """Get MSSQL connection using runtime config (no fallback)."""
    if not runtime_config:
        raise Exception("Database connection not configured. Please use Connection Settings to configure your database credentials.")
    
    try:
        config = load_config(runtime_config)
        return pyodbc.connect(config.mssql.get_connection_string())
    except Exception as e:
        logging.error(f"Error connecting to MSSQL: {e}")
        raise


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
    
    socketio.emit('progress', {
        'status': 'error',
        'error': error,
        'phase': migration_state['current_phase'],
        'message': f"Error: {error}"
    })


def get_available_modules() -> Dict[str, Dict[str, Any]]:
    """Scan reference directory for migration modules."""
    reference_dir = 'reference'
    modules = {}
    
    if not os.path.exists(reference_dir):
        return modules
    
    # Pattern: V001__description.sql
    pattern = re.compile(r'V(\d+)__(.*)\.sql')
    
    for filename in os.listdir(reference_dir):
        match = pattern.match(filename)
        if match:
            version = match.group(1)
            raw_name = match.group(2)
            
            # Create a slug/key from the name (e.g. create_normalized_users_table -> users)
            # Find common patterns to simplify the key
            module_id = raw_name.replace('create_normalized_', '').replace('_table', '').replace('_tables', '')
            
            # Format a nice title
            title_parts = [p.capitalize() for p in module_id.split('_')]
            title = f"{' '.join(title_parts)} Tables (V{version})"
            
            # Try to get description from the first line of the SQL file
            description = f"Normalization script for {module_id} module."
            file_path = os.path.join(reference_dir, filename)
            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    first_line = f.readline().strip()
                    if first_line.startswith('--'):
                        description = first_line.lstrip('- ').strip()
            except Exception:
                pass
                
            modules[module_id] = {
                'id': module_id,
                'title': title,
                'description': description,
                'file': file_path.replace('\\', '/'),
                'version': int(version),
                'order': int(version)
            }
            
    return modules
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


def run_migration(selected_tables: List[str], translations_file: str = None, normalize: bool = False):
    """Run the full migration process."""
    global migration_state, TRANSLATION_DICT
    
    # Initialize connections
    mssql_conn = None
    pg_conn = None
    
    try:
        migration_state['status'] = 'running'
        migration_state['progress'] = 0
        migration_state['error'] = None
        
        # Load translation dict if file provided
        if translations_file:
            # TODO: Implement loading from file path/content
            pass
            
        emit_progress('init', 'Initializing connections...', 5)
        
        # Connect to databases using configured settings
        config = load_config(runtime_config)
        
        try:
            mssql_conn = pyodbc.connect(config.mssql.get_connection_string())
        except Exception as e:
            raise Exception(f"Failed to connect to MSSQL: {e}")
            
        try:
            pg_conn = psycopg2.connect(**config.postgresql.get_connection_params())
        except Exception as e:
            raise Exception(f"Failed to connect to PostgreSQL: {e}")
            
        mssql_cursor = mssql_conn.cursor()
        pg_cursor = pg_conn.cursor()
        
        # Initialize translation dictionary
        if translations_file and os.path.exists(translations_file):
            migration_main.TRANSLATION_DICT = load_translation_dict(translations_file)
        
        # Phase 0: Metadata
        emit_progress('metadata', 'Reading source metadata...', 10)
        
        # Update SCHEMAS_TO_MIGRATE in main module to match config
        # This is important because many functions in main.py rely on this global variable
        migration_main.SCHEMAS_TO_MIGRATE = config.migration.schemas_to_migrate
        TRANSLATION_DICT = migration_main.TRANSLATION_DICT
        
        # Update translate_identifier to use the loaded dict
        # The function in main.py uses the global TRANSLATION_DICT, so we just need to set it
        
        
        # Connect to databases
        emit_progress('connecting', 'Connecting to databases...', 5)
        
        # Use runtime config for both connections
        config = load_config(runtime_config)
        
        try:
            mssql_conn = pyodbc.connect(config.mssql.get_connection_string())
        except Exception as e:
            raise Exception(f"Failed to connect to MSSQL: {e}")
        
        try:
            pg_conn = psycopg2.connect(**config.postgresql.get_connection_params())
            pg_conn.autocommit = True
        except Exception as e:
            raise Exception(f"Failed to connect to PostgreSQL: {e}")
        
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
        
        # Phase 6: Validation
        emit_progress('validation', 'Performing data validation and integrity checks...', 95)
        
        from validation import DataValidator
        
        # Use connections that are already open
        validator = DataValidator(mssql_conn, pg_conn)
        
        # 1. Compare row counts
        emit_progress('validation', 'Comparing row counts...', 96)
        validator.compare_row_counts(metadata['tables'])
        
        # 2. Validate target data (duplicates, nulls, orphans)
        emit_progress('validation', 'Validating target data constraints...', 97)
        validator.validate_target_data(metadata['tables'])
        
        # 3. Spot checks
        emit_progress('validation', 'Performing spot checks on random records...', 98)
        validator.perform_spot_checks(metadata['tables'], sample_size=5)
        
        # Generate & Save Report
        report = validator.generate_report()
        report_file = 'migration_validation_report.txt'
        try:
            with open(report_file, 'w', encoding='utf-8') as f:
                f.write(report)
            logging.info(f"Validation report saved to {report_file}")
            emit_progress('validation', f'Validation complete. Report saved to {report_file}', 99)
        except Exception as e:
            logging.error(f"Could not save validation report: {e}")
            emit_progress('validation', 'Validation complete (failed to save report)', 99)

        # Emit validation summary to UI (optional, or just rely on the report)
        if validator.issues:
             emit_progress('validation', f'found {len(validator.issues)} validation issues. Check report.', 99)
             
        # Phase 7: Normalization (if requested)
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




@app.route('/api/connect', methods=['POST'])
def connect_database():
    """
    Validate connection settings and store them for the session.
    Expects JSON body with optional 'mssql' and 'postgresql' keys.
    """
    global runtime_config
    
    data = request.json
    overrides = {}
    
    if 'mssql' in data:
        overrides['mssql'] = data['mssql']
    if 'postgresql' in data:
        overrides['postgresql'] = data['postgresql']
        
    try:
        # Load config with these overrides to validate
        config = load_config(overrides)
        
        # Test MSSQL Connection
        try:
            conn_str = config.mssql.get_connection_string()
            with pyodbc.connect(conn_str, timeout=5) as conn:
                pass
        except Exception as e:
            return jsonify({'error': f'MSSQL Connection Failed: {str(e)}'}), 400

        # Test PostgreSQL Connection
        try:
            params = config.postgresql.get_connection_params()
            # Set a low connect timeout
            params['connect_timeout'] = 5
            with psycopg2.connect(**params) as conn:
                pass
        except Exception as e:
            return jsonify({'error': f'PostgreSQL Connection Failed: {str(e)}'}), 400

        # If successful, update the global runtime config
        runtime_config = overrides
        
        return jsonify({
            'message': 'Connections successful',
            'config_summary': config.display_summary()
        })
        
    except ValueError as ve:
        return jsonify({'error': str(ve)}), 400
    except Exception as e:
        return jsonify({'error': f'Unexpected error: {str(e)}'}), 500


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


@app.route('/api/modules', methods=['GET'])
def get_modules():
    """Get list of available migration modules."""
    try:
        modules = get_available_modules()
        # Return as a list sorted by order
        modules_list = sorted(modules.values(), key=lambda x: x['order'])
        return jsonify({'modules': modules_list})
    except Exception as e:
        logging.error(f"Error fetching modules: {e}")
        return jsonify({'error': str(e)}), 500


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
    
    # Map migration types to SQL files dynamically
    available_modules = get_available_modules()
    migration_files = {k: v['file'] for k, v in available_modules.items() if k in migration_types}
    
    # Validate all migration types
    invalid_types = [mt for mt in migration_types if mt not in available_modules]
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
        
        # Connect to PostgreSQL using runtime config
        config = load_config(runtime_config)
        try:
            pg_conn = psycopg2.connect(**config.postgresql.get_connection_params())
        except Exception as e:
            raise Exception(f"Failed to connect to PostgreSQL: {e}")
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
        
        # Validation Phase for Normalization
        emit_progress('validation', 'Performing schema integrity checks...', 95)
        
        
        from validation import DataValidator
        # For Phase 2 (Normalization), we validate Postgres Raw Tables vs Postgres Normalized Tables
        # No MSSQL connection required here as data is already in PG from Phase 1
        validator = DataValidator(pg_conn=pg_conn)
        
        # 1. Internal Row Count Comparison (Raw PG -> Normalized PG)
        emit_progress('validation', 'Analyzing SQL scripts for table mappings...', 96)
        
        def parse_sql_mappings(files_dict: Dict[str, str]) -> List[Tuple[str, str]]:
            """
            Parses SQL files to find 'INSERT INTO Target ... SELECT ... FROM Source' patterns.
            Returns a list of (Source, Target) tuples.
            """
            mappings = []
            
            # Regex to find INSERT INTO target
            # Group 1: Schema (optional), Group 2: Table
            # Note: We relax the regex to find all INSERT INTO occurrences
            insert_pattern = re.compile(r'INSERT\s+INTO\s+(?:"?(\w+)"?(?:\."?(\w+)"?)?)', re.IGNORECASE)
            
            # Regex to find FROM source
            # This is harder to associate 1:1 with INSERTs if they are far apart in a CTE
            # But usually they are somewhat close. 
            # For mapping validation, getting the TARGET table is the most important part
            # to scope validation. The SOURCE is less critical for the scope filter (it drives row count comparison).
            
            # Improved Strategy:
            # 1. Scan the whole file for INSERT INTO statements.
            # 2. For each INSERT, try to find a FROM clause following it?
            #    Or just extract all TARGET tables.
            
            for clean_name, file_path in files_dict.items():
                try:
                    with open(file_path, 'r', encoding='utf-8') as f:
                        content = f.read()
                        
                    # Clean comments
                    content = re.sub(r'--.*$', '', content, flags=re.MULTILINE) 
                    content = re.sub(r'/\*.*?\*/', '', content, flags=re.DOTALL)
                    
                    # Find all INSERT INTO targets
                    # We iterate through the matches
                    for match in insert_pattern.finditer(content):
                        # Extract Target
                        if match.group(2):
                            target_table = f"{match.group(1)}.{match.group(2)}"
                        else:
                            target_table = f"public.{match.group(1)}"
                        
                        # Just generic "Source" for now to satisfy the tuple requirement
                        # If we really need source for specific row count stats, we look for FROM nearby
                        # But for scoping validation, TARGET is key.
                        source_table = "Unknown" 
                        
                        # Try to find a FROM clause in the vicinity (next 500 chars?)
                        # This is fuzzy but better than nothing
                        start_pos = match.end()
                        search_window = content[start_pos:start_pos+2000] # reasonable window
                        
                        from_match = re.search(r'FROM\s+(?:"?(\w+)"?(?:\."?(\w+)"?)?)', search_window, re.IGNORECASE)
                        if from_match:
                             if from_match.group(2):
                                 source_table = f"{from_match.group(1)}.{from_match.group(2)}"
                             else:
                                 source_table = f"public.{from_match.group(1)}"
                        
                        mappings.append((source_table, target_table))
                        logging.info(f"Discovered Mapping: {source_table} -> {target_table}")
                        
                except Exception as e:
                    logging.warning(f"Error parsing SQL file {file_path}: {e}")
            
            return mappings

        # Parse mappings dynamically from the execution files
        # We pass the dictionary { 'V000...': 'path/to/file' }
        mappings = parse_sql_mappings(migration_files)
        
        # If no mappings found (fallback or error), use hardcoded defaults? 
        # Better to warn and proceed with empty list or basic set.
        # If no mappings found, log it.
        if not mappings:
             logging.warning("No mappings discovered from SQL (likely schema-only migration).")
        
        # Call internal comparison
        validator.compare_internal_counts(mappings)
        
        # 2. Schema Integrity Checks
        emit_progress('validation', 'Performing schema integrity checks...', 98)
        
        # Validate 'public' schema (where normalized tables are usually created)
        # Scope validation to only the tables affected by the migration
        target_tables = [m[1] for m in mappings]
        validator.validate_schema_integrity(schema='public', table_filter=target_tables)
        
        # 2.1 Column Redundancy Check
        emit_progress('validation', 'Checking for column redundancy...', 98)
        validator.check_column_redundancy(schema='public', table_filter=target_tables)
        
        # Generate Report
        report = validator.generate_report()
        report_file = 'normalization_validation_report.txt'
        try:
            with open(report_file, 'w', encoding='utf-8') as f:
                f.write(report)
            logging.info(f"Normalization validation report saved to {report_file}")
            emit_progress('validation', f'Validation complete. Report saved to {report_file}', 100)
        except Exception as e:
            logging.error(f"Could not save validation report: {e}")
        
        # Cleanup
        pg_cursor.close()
        pg_conn.close()
        
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


@app.route('/api/report', methods=['GET'])
def get_validation_report():
    """Get the latest validation report content."""
    report_type = request.args.get('type', 'normalization') # normalization or migration
    filename = 'normalization_validation_report.txt' if report_type == 'normalization' else 'migration_validation_report.txt'
    
    if not os.path.exists(filename):
        return jsonify({'content': 'No report generated yet.'})
        
    try:
        with open(filename, 'r', encoding='utf-8') as f:
            content = f.read()
        return jsonify({'content': content})
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@app.route('/api/report/download', methods=['GET'])
def download_validation_report():
    """Download the latest validation report."""
    report_type = request.args.get('type', 'normalization')
    filename = 'normalization_validation_report.txt' if report_type == 'normalization' else 'migration_validation_report.txt'
    
    if not os.path.exists(filename):
        return jsonify({'error': 'Report not found'}), 404
        
    try:
        return send_from_directory(
            os.getcwd(), 
            filename, 
            as_attachment=True, 
            download_name=f'{report_type}_validation_report.txt'
        )
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@socketio.on('connect')
def handle_connect():
    """Handle WebSocket connection."""
    emit('connected', {'message': 'Connected to migration server'})


if __name__ == '__main__':
    logging.basicConfig(level=logging.INFO)
    socketio.run(app, host='0.0.0.0', port=5000, debug=True)

