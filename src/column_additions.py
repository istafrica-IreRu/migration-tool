"""
Module for adding new columns to migrated tables after Phase 1 (raw migration).
This ensures columns exist before normalization runs.
"""
import logging
import psycopg2
import json
import os

logger = logging.getLogger(__name__)


def update_schema_definition(new_columns_map: dict) -> None:
    """
    Updates the schema_definition.json file with newly added columns.
    
    Args:
        new_columns_map: Dictionary mapping table names to their new columns
                        Format: {'TableName': [('column_name', 'data_type', nullable, default, description), ...]}
    """
    # Determine the path to schema_definition.json
    # Assuming the script is run from the project root or src directory
    current_dir = os.path.dirname(os.path.abspath(__file__))
    project_root = os.path.dirname(current_dir)  # Go up one level from src/
    schema_file_path = os.path.join(project_root, 'resources', 'schema_definition.json')
    
    if not os.path.exists(schema_file_path):
        logger.warning(f"Schema definition file not found at {schema_file_path}. Skipping schema update.")
        return
    
    try:
        # Read the current schema definition
        with open(schema_file_path, 'r', encoding='utf-8') as f:
            schema_definition = json.load(f)
        
        # Update the schema with new columns
        for table_name, columns in new_columns_map.items():
            if table_name not in schema_definition:
                # Create new entry for this table
                schema_definition[table_name] = {"new_columns": []}
                logger.info(f"Created new schema entry for table '{table_name}'")
            
            if "new_columns" not in schema_definition[table_name]:
                schema_definition[table_name]["new_columns"] = []
            
            # Add each column to the schema
            for col_info in columns:
                column_name, data_type = col_info[0], col_info[1]
                nullable = col_info[2] if len(col_info) > 2 else False
                default = col_info[3] if len(col_info) > 3 else None
                description = col_info[4] if len(col_info) > 4 else f"{column_name} column"
                
                # Check if column already exists
                existing_columns = [col['name'] for col in schema_definition[table_name]["new_columns"]]
                if column_name in existing_columns:
                    logger.info(f"Column '{column_name}' already exists in schema for table '{table_name}'. Skipping.")
                    continue
                
                # Create column definition
                column_def = {
                    "name": column_name,
                    "type": data_type,
                    "nullable": nullable,
                }
                
                if default is not None:
                    column_def["default"] = default
                
                column_def["description"] = description
                
                schema_definition[table_name]["new_columns"].append(column_def)
                logger.info(f"Added column '{column_name}' to schema definition for table '{table_name}'")
        
        # Write the updated schema back to the file
        with open(schema_file_path, 'w', encoding='utf-8') as f:
            json.dump(schema_definition, f, indent=4)
        
        logger.info(f"Successfully updated schema definition file: {schema_file_path}")
        
    except Exception as e:
        logger.error(f"Error updating schema definition file: {e}")


def add_new_columns_to_tables(pg_cursor: psycopg2.extensions.cursor) -> None:
    """
    Adds new columns to migrated tables after raw migration.
    This ensures columns exist before normalization runs.
    
    Args:
        pg_cursor: PostgreSQL database cursor
    """
    logger.info("--- Phase 3.5: Adding New Columns to Migrated Tables ---")
    
    # Define which tables need new columns
    # Format: 'schema.table': [('column_name', 'data_type', nullable, default, description), ...]
    NEW_COLUMNS = {
        'public."ApplicantTable"': [
            ('UserID', 'INTEGER', True, None, 'User ID reference'),
        ],
        # Add more tables and columns as needed
        # Example:
        # 'public."Students"': [
        #     ('UserID', 'INTEGER', False, '0', 'User ID reference'),
        #     ('SomeOtherColumn', 'VARCHAR(255)', True, None, 'Some description'),
        # ],
    }
    
    # Map for schema definition update (table name without schema prefix)
    schema_update_map = {}
    
    for table_key, columns in NEW_COLUMNS.items():
        try:
            for col_info in columns:
                column_name = col_info[0]
                data_type = col_info[1]
                
                alter_sql = f'''
                ALTER TABLE {table_key}
                ADD COLUMN IF NOT EXISTS "{column_name}" {data_type};
                '''
                
                logger.info(f"Adding column '{column_name}' ({data_type}) to {table_key}")
                pg_cursor.execute(alter_sql)
            
            # Extract table name for schema definition update
            # Remove schema prefix and quotes: 'public."ApplicantTable"' -> 'ApplicantTable'
            table_name = table_key.split('.')[-1].strip('"')
            schema_update_map[table_name] = columns
                
        except psycopg2.Error as e:
            logger.error(f"Error adding columns to {table_key}: {e}")
            pg_cursor.execute("ROLLBACK")
            # Continue with other tables even if one fails
            continue
    
    logger.info("New columns addition complete.")
    
    # Update the schema definition file
    if schema_update_map:
        logger.info("Updating schema definition file...")
        update_schema_definition(schema_update_map)
