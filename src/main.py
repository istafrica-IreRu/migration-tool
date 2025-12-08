import argparse
import pyodbc
import psycopg2
from psycopg2 import extras
import logging
from collections import defaultdict
import re
import json
from typing import Dict, List, Set, Tuple, Any

# --- Configuration ---
# MSSQL Connection Details
MSSQL_SERVER = 'a_wanderer'
MSSQL_DATABASE = 'wsdata'
MSSQL_USERNAME = 'ws_admin'
MSSQL_PASSWORD = '123'

# PostgreSQL Connection Details
PG_HOST = 'localhost'
PG_DATABASE = 'wsdata_v4'
PG_USER = 'postgres'
PG_PASSWORD = '123'
PG_PORT = '5432'

# IMPORTANT: Add all schemas you want to migrate to this list
SCHEMAS_TO_MIGRATE = ['dbo', 'winSCHOOLPlus']

# Global variables for command line arguments
TABLES_TO_MIGRATE: List[str] = []
TRANSLATION_DICT: Dict[str, str] = {}

# Import configuration from env_config module
# Note: The original code didn't use env_config but defined vars above. 
# I will keep the structure consistent with what I read, but add the new import.
from column_additions import add_new_columns_to_tables

# --- Logging Configuration ---
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

# --- Data Type Mapping (MSSQL to PostgreSQL) ---
DATA_TYPE_MAP = {
    'int': 'INTEGER',
    'bigint': 'BIGINT',
    'smallint': 'SMALLINT',
    'tinyint': 'SMALLINT',
    'varchar': 'VARCHAR',
    'nvarchar': 'VARCHAR',
    'text': 'TEXT',
    'ntext': 'TEXT',
    'char': 'CHAR',
    'nchar': 'CHAR',
    'float': 'DOUBLE PRECISION',
    'real': 'REAL',
    'decimal': 'NUMERIC',
    'numeric': 'NUMERIC',
    'money': 'NUMERIC(19, 4)',
    'smallmoney': 'NUMERIC(10, 4)',
    'bit': 'BOOLEAN',
    'datetime': 'TIMESTAMP',
    'datetime2': 'TIMESTAMP',
    'smalldatetime': 'TIMESTAMP',
    'date': 'DATE',
    'time': 'TIME',
    'uniqueidentifier': 'UUID',
    'varbinary': 'BYTEA',
    'binary': 'BYTEA',
    'image': 'BYTEA',
    'xml': 'XML',
    'timestamp': 'BYTEA',
}


def translate_identifier(identifier: str) -> str:
    """
    Translates a German identifier to English using the translation dictionary.
    If no translation is found, returns the original identifier.
    """
    if not TRANSLATION_DICT:
        return identifier

    # Remove any existing quotes
    clean_identifier = identifier.replace('"', '').replace('[', '').replace(']', '')

    # Try to translate the whole identifier first (for table names)
    if clean_identifier in TRANSLATION_DICT:
        return TRANSLATION_DICT[clean_identifier]

    # Try to translate parts split by underscores (for column names)
    parts = clean_identifier.split('_')
    translated_parts = []
    for part in parts:
        translated_parts.append(TRANSLATION_DICT.get(part, part))

    translated = '_'.join(translated_parts)

    # If we didn't find any translations, return the original
    if translated == clean_identifier:
        return identifier

    return translated


def get_mssql_connection() -> pyodbc.Connection:
    """Establishes and returns an MSSQL database connection."""
    try:
        conn_str = f"DRIVER={{ODBC Driver 17 for SQL Server}};SERVER={MSSQL_SERVER};DATABASE={MSSQL_DATABASE};UID={MSSQL_USERNAME};PWD={MSSQL_PASSWORD};"
        conn = pyodbc.connect(conn_str)
        logging.info("Successfully connected to MSSQL server.")
        return conn
    except pyodbc.Error as ex:
        logging.error(f"Error connecting to MSSQL: {ex}")
        raise


def get_pg_connection() -> psycopg2.extensions.connection:
    """Establishes and returns a PostgreSQL database connection."""
    try:
        conn = psycopg2.connect(
            host=PG_HOST,
            database=PG_DATABASE,
            user=PG_USER,
            password=PG_PASSWORD,
            port=PG_PORT
        )
        logging.info("Successfully connected to PostgreSQL server.")
        return conn
    except psycopg2.Error as ex:
        logging.error(f"Error connecting to PostgreSQL: {ex}")
        raise


def get_mssql_metadata(mssql_cursor: pyodbc.Cursor) -> Dict[str, Any]:
    """Retrieves all necessary metadata from MSSQL in one go."""
    metadata = {
        'schemas': set(),
        'tables': {},
        'views': {},
        'dependencies': defaultdict(list),
        'original_names': {}  # Track original names for translation
    }

    if not SCHEMAS_TO_MIGRATE:
        logging.error("The SCHEMAS_TO_MIGRATE list cannot be empty. Please specify at least one schema.")
        raise ValueError("SCHEMAS_TO_MIGRATE list is empty.")

    schemas_filter = ", ".join([f"'{s}'" for s in SCHEMAS_TO_MIGRATE])

    # 1. Schemas
    mssql_cursor.execute(f"SELECT schema_name FROM INFORMATION_SCHEMA.SCHEMATA WHERE schema_name IN ({schemas_filter})")
    for row in mssql_cursor.fetchall():
        metadata['schemas'].add(row.schema_name)

    # 2. Tables and Columns
    query = f"""
    SELECT 
        t.TABLE_SCHEMA, t.TABLE_NAME, c.COLUMN_NAME, c.DATA_TYPE, 
        c.CHARACTER_MAXIMUM_LENGTH, c.NUMERIC_PRECISION, c.NUMERIC_SCALE, 
        c.IS_NULLABLE, c.COLUMN_DEFAULT, 
        ic.column_id AS IS_IDENTITY
    FROM INFORMATION_SCHEMA.TABLES t
    JOIN INFORMATION_SCHEMA.COLUMNS c ON t.TABLE_SCHEMA = c.TABLE_SCHEMA AND t.TABLE_NAME = c.TABLE_NAME
    LEFT JOIN sys.identity_columns ic ON ic.object_id = OBJECT_ID(t.TABLE_SCHEMA + '.' + t.TABLE_NAME) AND ic.name = c.COLUMN_NAME
    WHERE t.TABLE_TYPE = 'BASE TABLE' AND t.TABLE_SCHEMA IN ({schemas_filter})
    ORDER BY t.TABLE_SCHEMA, t.TABLE_NAME, c.ORDINAL_POSITION;
    """
    mssql_cursor.execute(query)
    for row in mssql_cursor.fetchall():
        original_table_key = f"{row.TABLE_SCHEMA}.{row.TABLE_NAME}"
        translated_table_name = translate_identifier(row.TABLE_NAME)
        table_key = f"{row.TABLE_SCHEMA}.{translated_table_name}"

        # Store original names for reference
        metadata['original_names'][table_key] = original_table_key

        if table_key not in metadata['tables']:
            metadata['tables'][table_key] = {
                'columns': [],
                'constraints': [],
                'indexes': [],
                'original_columns': {}  # Track original column names
            }

        # Translate column name
        translated_col_name = translate_identifier(row.COLUMN_NAME)
        metadata['tables'][table_key]['original_columns'][translated_col_name] = row.COLUMN_NAME
        metadata['tables'][table_key]['columns'].append(row)

    # 3. Primary Keys, Unique Constraints
    query = f"""
    SELECT 
        tc.TABLE_SCHEMA, tc.TABLE_NAME, tc.CONSTRAINT_NAME, tc.CONSTRAINT_TYPE,
        kcu.COLUMN_NAME
    FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS tc
    JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE kcu ON tc.CONSTRAINT_NAME = kcu.CONSTRAINT_NAME 
        AND tc.TABLE_SCHEMA = kcu.TABLE_SCHEMA AND tc.TABLE_NAME = kcu.TABLE_NAME
    WHERE tc.TABLE_SCHEMA IN ({schemas_filter}) AND tc.CONSTRAINT_TYPE IN ('PRIMARY KEY', 'UNIQUE')
    ORDER BY tc.TABLE_SCHEMA, tc.TABLE_NAME, kcu.ORDINAL_POSITION;
    """
    mssql_cursor.execute(query)
    constraints = defaultdict(lambda: {'type': '', 'columns': []})
    for row in mssql_cursor.fetchall():
        translated_table_name = translate_identifier(row.TABLE_NAME)
        translated_col_name = translate_identifier(row.COLUMN_NAME)
        key = (row.TABLE_SCHEMA, translated_table_name, row.CONSTRAINT_NAME)
        constraints[key]['type'] = row.CONSTRAINT_TYPE
        constraints[key]['columns'].append(translated_col_name)

    for (schema, table, name), data in constraints.items():
        table_key = f"{schema}.{table}"
        if table_key in metadata['tables']:
            metadata['tables'][table_key]['constraints'].append(
                {'name': name, 'type': data['type'], 'definition': data['columns']})

    # 4. Foreign Keys and Dependencies
    query = f"""
    SELECT 
        fk.name AS constraint_name,
        OBJECT_SCHEMA_NAME(fk.parent_object_id) AS child_schema,
        OBJECT_NAME(fk.parent_object_id) AS child_table,
        pc.name AS child_column,
        OBJECT_SCHEMA_NAME(fk.referenced_object_id) AS parent_schema,
        OBJECT_NAME(fk.referenced_object_id) AS parent_table,
        rc.name AS parent_column
    FROM sys.foreign_keys AS fk
    INNER JOIN sys.foreign_key_columns AS fkc ON fk.object_id = fkc.constraint_object_id
    INNER JOIN sys.columns AS pc ON fkc.parent_object_id = pc.object_id AND fkc.parent_column_id = pc.column_id
    INNER JOIN sys.columns AS rc ON fkc.referenced_object_id = rc.object_id AND fkc.referenced_column_id = rc.column_id
    WHERE OBJECT_SCHEMA_NAME(fk.parent_object_id) IN ({schemas_filter})
    ORDER BY child_schema, child_table;
    """
    mssql_cursor.execute(query)
    fks = defaultdict(lambda: {'parent_table': '', 'parent_columns': [], 'child_columns': []})
    for row in mssql_cursor.fetchall():
        # Translate table and column names
        translated_parent_table = translate_identifier(row.parent_table)
        translated_child_table = translate_identifier(row.child_table)
        translated_parent_col = translate_identifier(row.parent_column)
        translated_child_col = translate_identifier(row.child_column)

        parent_key = f"{row.parent_schema}.{translated_parent_table}"
        child_key = f"{row.child_schema}.{translated_child_table}"

        if parent_key != child_key and child_key in metadata['tables']:
            metadata['dependencies'][child_key].append(parent_key)

        fk_key = (child_key, row.constraint_name)
        fks[fk_key]['parent_table'] = parent_key
        fks[fk_key]['child_columns'].append(translated_child_col)
        fks[fk_key]['parent_columns'].append(translated_parent_col)

    for (child_table, name), data in fks.items():
        if child_table in metadata['tables']:
            metadata['tables'][child_table]['constraints'].append(
                {'name': name, 'type': 'FOREIGN KEY', 'definition': data})

    # 5. Indexes
    query = f"""
    SELECT 
        s.name AS schema_name,
        t.name AS table_name,
        i.name AS index_name,
        ic.key_ordinal,
        c.name AS column_name,
        i.is_unique,
        i.type_desc
    FROM sys.indexes i
    JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
    JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
    JOIN sys.tables t ON i.object_id = t.object_id
    JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE i.is_primary_key = 0 AND i.is_unique_constraint = 0 AND s.name IN ({schemas_filter})
    ORDER BY s.name, t.name, i.name, ic.key_ordinal;
    """
    mssql_cursor.execute(query)
    indexes = defaultdict(lambda: {'unique': False, 'columns': []})
    for row in mssql_cursor.fetchall():
        translated_table_name = translate_identifier(row.table_name)
        translated_col_name = translate_identifier(row.column_name)
        key = (row.schema_name, translated_table_name, row.index_name)
        indexes[key]['unique'] = row.is_unique
        indexes[key]['columns'].append(translated_col_name)

    for (schema, table, name), data in indexes.items():
        table_key = f"{schema}.{table}"
        if table_key in metadata['tables']:
            metadata['tables'][table_key]['indexes'].append(
                {'name': name, 'unique': data['unique'], 'columns': data['columns']})

    # 6. Views
    query = f"SELECT TABLE_SCHEMA, TABLE_NAME, VIEW_DEFINITION FROM INFORMATION_SCHEMA.VIEWS WHERE TABLE_SCHEMA IN ({schemas_filter})"
    mssql_cursor.execute(query)
    for row in mssql_cursor.fetchall():
        translated_view_name = translate_identifier(row.TABLE_NAME)
        view_key = f"{row.TABLE_SCHEMA}.{translated_view_name}"
        metadata['views'][view_key] = row.VIEW_DEFINITION
        metadata['original_names'][view_key] = f"{row.TABLE_SCHEMA}.{row.TABLE_NAME}"

    return metadata


def topological_sort(dependencies: Dict[str, List[str]], all_tables: List[str]) -> List[str]:
    """Sorts tables based on FK dependencies to ensure correct insertion order."""
    sorted_order = []
    in_degree = {u: 0 for u in all_tables}
    adj = {u: [] for u in all_tables}

    for u, deps in dependencies.items():
        for v in deps:
            if u in adj and v in adj:
                adj[v].append(u)
                in_degree[u] += 1

    queue = [u for u in all_tables if in_degree[u] == 0]

    while queue:
        u = queue.pop(0)
        sorted_order.append(u)
        for v in adj.get(u, []):
            in_degree[v] -= 1
            if in_degree[v] == 0:
                queue.append(v)

    if len(sorted_order) == len(all_tables):
        logging.info("Table migration order determined successfully.")
        return sorted_order
    else:
        cycles = set(all_tables) - set(sorted_order)
        logging.warning(
            f"Circular dependencies detected involving: {cycles}. These tables will be appended. You may need to handle their FKs manually.")
        return sorted_order + list(cycles)


def migrate_schemas(pg_cursor: psycopg2.extensions.cursor, schemas: Set[str]) -> None:
    """Creates schemas in PostgreSQL."""
    logging.info("--- Phase 1: Migrating Schemas ---")
    for schema_name in schemas:
        if schema_name == 'dbo':
            logging.info("Mapping MSSQL 'dbo' schema to PostgreSQL 'public' schema (default).")
            continue
        try:
            logging.info(f"Creating schema '{schema_name}'...")
            pg_cursor.execute(f'CREATE SCHEMA IF NOT EXISTS "{schema_name}"')
        except psycopg2.Error as e:
            logging.error(f"Error creating schema '{schema_name}': {e}")
            raise
    logging.info("Schema migration complete.")


def drop_table_if_exists(pg_cursor: psycopg2.extensions.cursor, table_key: str) -> None:
    """Drops a table if it exists, including its sequences."""
    try:
        # Drop the table (CASCADE will drop dependent sequences)
        pg_cursor.execute(f'DROP TABLE IF EXISTS {table_key} CASCADE')
        logging.info(f"Dropped existing table: {table_key}")
    except psycopg2.Error as e:
        logging.warning(f"Could not drop table {table_key}: {e}")


def migrate_tables_structure(pg_cursor: psycopg2.extensions.cursor, tables_metadata: Dict[str, Any]) -> None:
    """Creates table structures in PostgreSQL without constraints."""
    logging.info("--- Phase 2: Migrating Table Structures ---")

    for table_key, data in tables_metadata.items():
        schema_name, table_name = table_key.split('.')
        pg_table_key = f'"{schema_name}"."{table_name}"' if schema_name != 'dbo' else f'public."{table_name}"'

        # Drop existing table to avoid conflicts
        drop_table_if_exists(pg_cursor, pg_table_key)

        columns_sql = []
        used_column_names = set()  # Track used column names to handle duplicates

        for col in data['columns']:
            # Get the translated column name
            base_translated_name = translate_identifier(col.COLUMN_NAME)
            translated_col_name = base_translated_name

            # Handle duplicate column names after translation
            counter = 1
            while translated_col_name.lower() in used_column_names:
                translated_col_name = f"{base_translated_name}_{counter}"
                counter += 1
                logging.warning(
                    f"Column name conflict resolved: '{base_translated_name}' -> '{translated_col_name}' in table {table_key}")

            used_column_names.add(translated_col_name.lower())

            # Update the metadata to reflect the final column name
            data['original_columns'][translated_col_name] = col.COLUMN_NAME

            mssql_type = col.DATA_TYPE.lower()
            pg_type = DATA_TYPE_MAP.get(mssql_type, 'TEXT')

            if mssql_type.startswith(('nvar', 'var')) and col.CHARACTER_MAXIMUM_LENGTH == -1:
                pg_type = 'TEXT'
            elif mssql_type in ['varchar', 'nvarchar', 'char', 'nchar'] and col.CHARACTER_MAXIMUM_LENGTH:
                pg_type += f"({col.CHARACTER_MAXIMUM_LENGTH})"
            elif mssql_type in ['decimal', 'numeric'] and col.NUMERIC_PRECISION:
                scale = col.NUMERIC_SCALE if col.NUMERIC_SCALE is not None else 0
                pg_type += f"({col.NUMERIC_PRECISION}, {scale})"

            if col.IS_IDENTITY:
                pg_type = 'BIGSERIAL' if pg_type == 'BIGINT' else 'SERIAL'

            is_nullable = "NULL" if col.IS_NULLABLE == 'YES' else "NOT NULL"

            default_val = ''
            if col.COLUMN_DEFAULT and not col.IS_IDENTITY:
                # Translate MSSQL default value syntax like ((1)) or ('some_string')
                default_val_cleaned = col.COLUMN_DEFAULT.strip('()')

                # For string literals, MSSQL uses ('foo'), PG uses 'foo'
                if default_val_cleaned.startswith("'") and default_val_cleaned.endswith("'"):
                    default_val = f"DEFAULT {default_val_cleaned}"
                # For numbers, MSSQL might use ((1)), PG uses 1
                elif default_val_cleaned.replace('.', '').replace('-', '').isdigit():
                    default_val = f"DEFAULT {default_val_cleaned}"
                # Add other common default functions if needed
                elif 'getdate()' in default_val_cleaned.lower():
                    default_val = 'DEFAULT NOW()'
                else:
                    logging.warning(
                        f"Could not automatically translate default value '{col.COLUMN_DEFAULT}' on {table_key}.{translated_col_name}. Manual check required.")

            column_def = f'"{translated_col_name}" {pg_type} {is_nullable} {default_val}'.strip()
            columns_sql.append(column_def)

        create_sql = f"CREATE TABLE IF NOT EXISTS {pg_table_key} (\n    " + ",\n    ".join(columns_sql) + "\n);"

        try:
            logging.info(f"Creating table: {pg_table_key}")
            pg_cursor.execute(create_sql)
        except psycopg2.Error as e:
            logging.error(f"Error creating table {pg_table_key}: {e}\nSQL: {create_sql}")
            pg_cursor.execute("ROLLBACK")
            raise

    logging.info("Table structure migration complete.")


def migrate_data(mssql_cursor: pyodbc.Cursor, pg_conn: psycopg2.extensions.connection,
                 sorted_tables: List[str], tables_metadata: Dict[str, Any]) -> None:
    """Migrates data for all tables in the specified order, cleaning NUL characters."""
    logging.info("--- Phase 3: Migrating Data ---")
    pg_cursor = pg_conn.cursor()

    for table_key in sorted_tables:
        if table_key not in tables_metadata:
            logging.warning(f"Table {table_key} not found in metadata, skipping...")
            continue

        schema_name, table_name = table_key.split('.')

        # Get the original table data from metadata
        table_data = tables_metadata[table_key]

        # The original table name is stored in the first column's metadata
        original_schema = table_data['columns'][0].TABLE_SCHEMA
        original_table = table_data['columns'][0].TABLE_NAME

        pg_table_key = f'"{schema_name}"."{table_name}"' if schema_name != 'dbo' else f'public."{table_name}"'

        try:
            # Get original column names for SELECT statement and final translated names for INSERT
            original_columns = []
            final_translated_columns = []

            # Build a mapping of original to final translated names
            used_column_names = set()
            for col in table_data['columns']:
                original_column = col.COLUMN_NAME
                base_translated_name = translate_identifier(original_column)
                final_translated_name = base_translated_name

                # Handle duplicate column names after translation (same logic as table creation)
                counter = 1
                while final_translated_name.lower() in used_column_names:
                    final_translated_name = f"{base_translated_name}_{counter}"
                    counter += 1

                used_column_names.add(final_translated_name.lower())

                original_columns.append(original_column)
                final_translated_columns.append(final_translated_name)

            select_columns = ', '.join([f'[{col}]' for col in original_columns])

            # Query MSSQL using the original table name
            mssql_cursor.execute(f'SELECT {select_columns} FROM "{original_schema}"."{original_table}"')

            # Insert into PostgreSQL using final translated names
            insert_columns = ', '.join([f'"{col}"' for col in final_translated_columns])
            insert_sql = f'INSERT INTO {pg_table_key} ({insert_columns}) VALUES %s'

            page_size = 1000
            rows_migrated = 0
            while True:
                rows = mssql_cursor.fetchmany(page_size)
                if not rows:
                    break

                # Clean the data to remove NUL (0x00) characters
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
                    if rows_migrated % 10000 == 0:  # Log every 10k rows
                        logging.info(f"Migrated {rows_migrated} rows for table {pg_table_key}...")

            pg_conn.commit()
            if rows_migrated == 0:
                logging.info(f"No data to migrate for table {pg_table_key}.")
            else:
                logging.info(f"Successfully migrated a total of {rows_migrated} rows for table {pg_table_key}.")

        except (pyodbc.Error, psycopg2.Error) as e:
            logging.error(f"Error migrating data for table {pg_table_key}: {e}")
            pg_conn.rollback()
            raise

    pg_cursor.close()
    logging.info("Data migration complete.")


def get_final_column_name(original_col_name: str, table_columns: List[Any]) -> str:
    """Get the final translated column name, handling duplicates consistently."""
    used_column_names = set()

    for col in table_columns:
        base_translated_name = translate_identifier(col.COLUMN_NAME)
        final_translated_name = base_translated_name

        # Handle duplicate column names after translation
        counter = 1
        while final_translated_name.lower() in used_column_names:
            final_translated_name = f"{base_translated_name}_{counter}"
            counter += 1

        used_column_names.add(final_translated_name.lower())

        if col.COLUMN_NAME == original_col_name:
            return final_translated_name

    # Fallback - should not happen
    return translate_identifier(original_col_name)


def migrate_constraints_and_indexes(pg_cursor: psycopg2.extensions.cursor, tables_metadata: Dict[str, Any]) -> None:
    """Adds primary keys, foreign keys, constraints, and indexes."""
    logging.info("--- Phase 4: Migrating Constraints and Indexes ---")

    # First pass: Primary Keys and Unique constraints
    for table_key, data in tables_metadata.items():
        schema_name, table_name = table_key.split('.')
        pg_table_key = f'"{schema_name}"."{table_name}"' if schema_name != 'dbo' else f'public."{table_name}"'

        for constraint in data.get('constraints', []):
            if constraint['type'] in ('PRIMARY KEY', 'UNIQUE'):
                constraint_type = constraint['type']
                constraint_name = constraint['name']

                # Get final column names (handling duplicates)
                final_columns = []
                for col_name in constraint['definition']:
                    # Find the original column name that was translated to this
                    original_col = None
                    for col in data['columns']:
                        if translate_identifier(col.COLUMN_NAME) == col_name:
                            original_col = col.COLUMN_NAME
                            break

                    if original_col:
                        final_col_name = get_final_column_name(original_col, data['columns'])
                        final_columns.append(final_col_name)
                    else:
                        final_columns.append(col_name)  # Fallback

                columns = '", "'.join(final_columns)
                sql = f'ALTER TABLE {pg_table_key} ADD CONSTRAINT "{constraint_name}" {constraint_type} ("{columns}");'
                try:
                    logging.info(f"Adding {constraint_type} to {pg_table_key} on columns ({columns}).")
                    pg_cursor.execute(sql)
                except psycopg2.Error as e:
                    logging.error(f"Error adding {constraint_type} '{constraint_name}' to {pg_table_key}: {e}")
                    pg_cursor.execute("ROLLBACK")

    # Second pass: Foreign Keys
    for table_key, data in tables_metadata.items():
        schema_name, table_name = table_key.split('.')
        pg_table_key = f'"{schema_name}"."{table_name}"' if schema_name != 'dbo' else f'public."{table_name}"'

        for constraint in data.get('constraints', []):
            if constraint['type'] == 'FOREIGN KEY':
                fk_data = constraint['definition']
                constraint_name = constraint['name']

                # Get final child column names
                final_child_cols = []
                for col_name in fk_data['child_columns']:
                    original_col = None
                    for col in data['columns']:
                        if translate_identifier(col.COLUMN_NAME) == col_name:
                            original_col = col.COLUMN_NAME
                            break

                    if original_col:
                        final_col_name = get_final_column_name(original_col, data['columns'])
                        final_child_cols.append(final_col_name)
                    else:
                        final_child_cols.append(col_name)

                child_cols = '", "'.join(final_child_cols)

                parent_schema, parent_table_name = fk_data['parent_table'].split('.')
                pg_parent_key = f'"{parent_schema}"."{parent_table_name}"' if parent_schema != 'dbo' else f'public."{parent_table_name}"'

                # Get final parent column names
                parent_table_data = tables_metadata.get(fk_data['parent_table'])
                final_parent_cols = []
                if parent_table_data:
                    for col_name in fk_data['parent_columns']:
                        original_col = None
                        for col in parent_table_data['columns']:
                            if translate_identifier(col.COLUMN_NAME) == col_name:
                                original_col = col.COLUMN_NAME
                                break

                        if original_col:
                            final_col_name = get_final_column_name(original_col, parent_table_data['columns'])
                            final_parent_cols.append(final_col_name)
                        else:
                            final_parent_cols.append(col_name)
                else:
                    final_parent_cols = fk_data['parent_columns']

                parent_cols = '", "'.join(final_parent_cols)

                sql = f'ALTER TABLE {pg_table_key} ADD CONSTRAINT "{constraint_name}" FOREIGN KEY ("{child_cols}") REFERENCES {pg_parent_key} ("{parent_cols}");'
                try:
                    logging.info(f"Adding FOREIGN KEY to {pg_table_key} referencing {pg_parent_key}.")
                    pg_cursor.execute(sql)
                except psycopg2.Error as e:
                    logging.error(f"Error adding FOREIGN KEY '{constraint_name}' to {pg_table_key}: {e}")
                    pg_cursor.execute("ROLLBACK")

    # Third pass: Indexes
    for table_key, data in tables_metadata.items():
        schema_name, table_name = table_key.split('.')
        pg_table_key = f'"{schema_name}"."{table_name}"' if schema_name != 'dbo' else f'public."{table_name}"'

        for index in data.get('indexes', []):
            index_name = index['name']

            # Get final column names for index
            final_index_cols = []
            for col_name in index['columns']:
                original_col = None
                for col in data['columns']:
                    if translate_identifier(col.COLUMN_NAME) == col_name:
                        original_col = col.COLUMN_NAME
                        break

                if original_col:
                    final_col_name = get_final_column_name(original_col, data['columns'])
                    final_index_cols.append(final_col_name)
                else:
                    final_index_cols.append(col_name)

            columns = '", "'.join(final_index_cols)
            unique_str = "UNIQUE" if index['unique'] else ""
            sql = f'CREATE {unique_str} INDEX IF NOT EXISTS "{index_name}" ON {pg_table_key} ("{columns}");'
            try:
                logging.info(f"Creating index '{index_name}' on {pg_table_key}.")
                pg_cursor.execute(sql)
            except psycopg2.Error as e:
                logging.error(f"Error creating index '{index_name}' on {pg_table_key}: {e}")
                pg_cursor.execute("ROLLBACK")

    # Update sequences for SERIAL columns
    logging.info("Updating sequences for SERIAL columns...")
    for table_key, data in tables_metadata.items():
        schema_name, table_name = table_key.split('.')
        pg_table_key = f'"{schema_name}"."{table_name}"' if schema_name != 'dbo' else f'public."{table_name}"'

        for col in data['columns']:
            if col.IS_IDENTITY:
                final_col_name = get_final_column_name(col.COLUMN_NAME, data['columns'])
                pg_seq_schema = 'public' if schema_name == 'dbo' else schema_name

                try:
                    sql = f"""SELECT setval(pg_get_serial_sequence('"{pg_seq_schema}"."{table_name}"', '{final_col_name}'), 
                                           COALESCE(MAX("{final_col_name}"), 1), 
                                           MAX("{final_col_name}") IS NOT NULL) 
                               FROM {pg_table_key};"""
                    pg_cursor.execute(sql)
                    logging.info(f"Updated sequence for {pg_table_key}.{final_col_name}.")
                except psycopg2.Error as e:
                    logging.warning(
                        f"Could not update sequence for {pg_table_key}.{final_col_name}. Manual check may be required. Error: {e}")
                    pg_cursor.execute("ROLLBACK")

    logging.info("Constraints and indexes migration complete.")


def translate_tsql_to_postgres(tsql: str, all_migrated_names: Dict[str, str]) -> str:
    """
    Translates a T-SQL view definition to PostgreSQL, systematically replacing
    all known table and view identifiers.
    """
    # Start with basic, safe replacements
    tsql = re.sub(r'(?i)\bGO\b', '', tsql)  # Remove GO commands
    tsql = re.sub(r'(?i)WITH\s*\(.*?SCHEMABINDING.*?\)', '', tsql, flags=re.DOTALL)  # Remove SCHEMABINDING
    tsql = tsql.strip().rstrip(';')

    # General function replacements
    replacements = {
        'GETDATE()': 'NOW()',
        'ISNULL(': 'COALESCE(',
        'LEN(': 'LENGTH(',
        'CHARINDEX(': 'STRPOS(',
        '[': '"',
        ']': '"',
    }
    for old, new in replacements.items():
        tsql = re.sub(r'(?i)\b' + re.escape(old) + r'\b', new, tsql)

    # Find and replace all known table/view identifiers
    for original_key, translated_key in all_migrated_names.items():
        original_schema, original_name = original_key.split('.')
        translated_schema, translated_name = translated_key.split('.')

        # PostgreSQL uses 'public' for 'dbo'
        if translated_schema == 'dbo':
            translated_schema = 'public'

        # Create a regex to find the original table name
        pattern = re.compile(
            r'(\[?"?' + re.escape(original_schema) + r'"?\]?\.)?\[?"?' + re.escape(original_name) + r'"?\]?',
            re.IGNORECASE
        )

        # The replacement is the new, fully qualified and quoted name
        replacement_str = f'"{translated_schema}"."{translated_name}"'
        tsql = pattern.sub(replacement_str, tsql)

    # Translate TOP N to LIMIT
    top_match = re.search(r'(?i)TOP\s+\(?\s*(\d+)\s*\)?', tsql)
    if top_match:
        limit = top_match.group(1)
        # Remove the TOP clause and append LIMIT at the end
        tsql = re.sub(r'(?i)\s*TOP\s+\(?\s*\d+\s*\)?\s*', ' ', tsql, count=1)
        if 'LIMIT' not in tsql.upper():
            tsql += f' LIMIT {limit}'

    # Remove the original "CREATE VIEW ... AS" part
    tsql = re.sub(r'(?i)^.*CREATE\s+VIEW\s+.*?\s+AS\s+', '', tsql, flags=re.DOTALL)

    return tsql.strip()


def migrate_views(pg_cursor: psycopg2.extensions.cursor, views_metadata: Dict[str, str],
                  tables_metadata: Dict[str, Any]) -> None:
    """Migrates views with dependency resolution"""
    logging.info("--- Phase 5: Migrating Views ---")

    # Create a comprehensive dictionary of all original and translated names
    all_names_map = {}
    for table_key, data in tables_metadata.items():
        if data['columns']:  # Ensure columns exist
            original_table_key = f"{data['columns'][0].TABLE_SCHEMA}.{data['columns'][0].TABLE_NAME}"
            all_names_map[original_table_key] = table_key

    for view_key, _ in views_metadata.items():
        schema, view_name = view_key.split('.')
        translated_view_name = translate_identifier(view_name)
        original_view_key = f"{schema}.{view_name}"
        all_names_map[original_view_key] = f"{schema}.{translated_view_name}"

    view_errors = []
    created_views = set()
    views_to_migrate = list(views_metadata.keys())

    # Use a loop to handle dependencies: create simple views first, then more complex ones
    max_attempts = len(views_to_migrate) + 1
    for attempt in range(max_attempts):
        if not views_to_migrate:
            break

        remaining_views = []
        for view_key in views_to_migrate:
            definition = views_metadata[view_key]
            schema_name, view_name = view_key.split('.')
            pg_view_key = f'"{schema_name}"."{view_name}"' if schema_name != 'dbo' else f'public."{view_name}"'

            pg_definition = ""
            try:
                # Pass the name map to the translator
                pg_definition = translate_tsql_to_postgres(definition, all_names_map)

                create_view_sql = f'CREATE OR REPLACE VIEW {pg_view_key} AS\n{pg_definition};'

                logging.info(f"Attempting to create view: {pg_view_key}")
                pg_cursor.execute(create_view_sql)
                created_views.add(view_key)
                logging.info(f"Successfully created view: {pg_view_key}")

            except psycopg2.Error as e:
                # If it fails, add it to the list to retry in the next pass
                remaining_views.append(view_key)
                # Log the error only on the final attempt
                if attempt == max_attempts - 1:
                    error_msg = f"Failed to create view {view_key}: {e}"
                    logging.error(error_msg)
                    view_errors.append({
                        'view': view_key,
                        'original_sql': definition,
                        'translated_sql': pg_definition,
                        'error': str(e)
                    })
                    pg_cursor.execute("ROLLBACK")

        # If no views were created in a full pass, we have a circular dependency
        if len(remaining_views) == len(views_to_migrate):
            logging.error("Circular dependency detected or views with missing tables. Aborting view migration.")
            for view_key in remaining_views:
                view_errors.append({
                    'view': view_key,
                    'error': 'Could not resolve dependencies or circular dependency detected.'
                })
            break

        views_to_migrate = remaining_views

    # Final report
    if view_errors:
        logging.error(f"Failed to migrate {len(view_errors)} views.")
        try:
            with open('view_errors.json', 'w', encoding='utf-8') as f:
                json.dump(view_errors, f, indent=4, ensure_ascii=False)
            logging.error("Review 'view_errors.json' for details on views that could not be migrated.")
        except IOError as e:
            logging.error(f"Could not write view_errors.json: {e}")

    logging.info(f"View migration complete. {len(created_views)}/{len(views_metadata)} views migrated.")


def load_tables_to_migrate(filename: str) -> List[str]:
    """Load list of tables to migrate from file."""
    try:
        with open(filename, encoding="utf-8") as f:
            tables = [line.strip() for line in f if line.strip()]
        logging.info(f"Loaded {len(tables)} tables to migrate from {filename}")
        return tables
    except FileNotFoundError:
        logging.error(f"Tables file not found: {filename}")
        raise
    except Exception as e:
        logging.error(f"Error reading tables file {filename}: {e}")
        raise


def load_translation_dict(filename: str) -> Dict[str, str]:
    """Load translation dictionary from JSON file."""
    try:
        with open(filename, encoding="utf-8") as f:
            translation_dict = json.load(f)
        logging.info(f"Loaded {len(translation_dict)} translations from {filename}")
        return translation_dict
    except FileNotFoundError:
        logging.error(f"Translation file not found: {filename}")
        raise
    except json.JSONDecodeError as e:
        logging.error(f"Invalid JSON in translation file {filename}: {e}")
        raise
    except Exception as e:
        logging.error(f"Error reading translation file {filename}: {e}")
        raise


def parse_args() -> argparse.Namespace:
    """Parse command line arguments."""
    parser = argparse.ArgumentParser(description="MSSQL to PostgreSQL migration utility.")
    parser.add_argument('--tables-file', type=str, required=False,
                        help="File with list of tables to migrate (one per line: schema.TableName). If not provided, all tables will be migrated.")
    parser.add_argument('--translations-file', type=str, required=True,
                        help="JSON file with translations dictionary")
    parser.add_argument('--drop-existing', action='store_true',
                        help="Drop existing tables before creating new ones")
    return parser.parse_args()


def main() -> None:
    """Main migration function."""
    mssql_conn = None
    pg_conn = None

    try:
        args = parse_args()
        global TABLES_TO_MIGRATE, TRANSLATION_DICT

        # Load tables to migrate (optional)
        if args.tables_file:
            TABLES_TO_MIGRATE = load_tables_to_migrate(args.tables_file)
            logging.info(f"Loaded {len(TABLES_TO_MIGRATE)} specific tables to migrate")
        else:
            TABLES_TO_MIGRATE = []
            logging.info("No tables file provided - will migrate ALL tables from specified schemas")

        TRANSLATION_DICT = load_translation_dict(args.translations_file)

        mssql_conn = get_mssql_connection()
        pg_conn = get_pg_connection()
        pg_conn.autocommit = True
        pg_cursor = pg_conn.cursor()

        logging.info("--- Phase 0: Fetching All MSSQL Metadata ---")
        mssql_cursor = mssql_conn.cursor()
        metadata = get_mssql_metadata(mssql_cursor)

        # Filter tables if specified, otherwise migrate all
        if TABLES_TO_MIGRATE:
            # Translate table names in TABLES_TO_MIGRATE
            translated_tables_to_migrate = []
            for table_ref in TABLES_TO_MIGRATE:
                if '.' not in table_ref:
                    logging.error(f"Invalid table reference '{table_ref}'. Expected format: schema.table")
                    continue
                schema, table = table_ref.split('.', 1)
                translated_table = translate_identifier(table)
                translated_tables_to_migrate.append(f"{schema}.{translated_table}")

            tables_to_keep = {t for t in metadata['tables'] if t in translated_tables_to_migrate}
            metadata['tables'] = {k: v for k, v in metadata['tables'].items() if k in tables_to_keep}
            migratable_tables = list(tables_to_keep)

            if not migratable_tables:
                logging.error("No matching tables found to migrate. Check your tables file and translation dictionary.")
                return

            logging.info(f"Migrating {len(migratable_tables)} specified tables: {migratable_tables}")
        else:
            # Migrate all tables from the specified schemas
            migratable_tables = list(metadata['tables'].keys())

            if not migratable_tables:
                logging.error(f"No tables found in schemas: {SCHEMAS_TO_MIGRATE}. Check your schema configuration.")
                return

            logging.info(
                f"Migrating ALL {len(migratable_tables)} tables from schemas {SCHEMAS_TO_MIGRATE}: {migratable_tables}")

        sorted_tables = topological_sort(metadata['dependencies'], migratable_tables)

        # Migration phases
        migrate_schemas(pg_cursor, metadata['schemas'])
        migrate_tables_structure(pg_cursor, metadata['tables'])

        pg_conn.autocommit = False
        migrate_data(mssql_cursor, pg_conn, sorted_tables, metadata['tables'])

        pg_conn.autocommit = True
        # Add new columns after data migration, before constraints
        add_new_columns_to_tables(pg_cursor)
        
        migrate_constraints_and_indexes(pg_cursor, metadata['tables'])
        migrate_views(pg_cursor, metadata['views'], metadata['tables'])

        logging.info("\n✅ ✅ ✅ MIGRATION PROCESS COMPLETED SUCCESSFULLY! ✅ ✅ ✅")

    except KeyboardInterrupt:
        logging.error("Migration interrupted by user.")
    except Exception as e:
        logging.critical(f"A critical error occurred during the migration process: {e}", exc_info=True)
    finally:
        if mssql_conn:
            try:
                mssql_conn.close()
                logging.info("MSSQL connection closed.")
            except Exception as e:
                logging.error(f"Error closing MSSQL connection: {e}")
        if pg_conn:
            try:
                pg_conn.close()
                logging.info("PostgreSQL connection closed.")
            except Exception as e:
                logging.error(f"Error closing PostgreSQL connection: {e}")


if __name__ == "__main__":
    main()