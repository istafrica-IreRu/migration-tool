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
    Reads column additions from SQL file for easier maintenance.
    
    Args:
        pg_cursor: PostgreSQL database cursor
    """
    print("\n" + "=" * 60)
    print("PHASE 3.5: ADDING NEW COLUMNS TO MIGRATED TABLES")
    print("=" * 60)
    logger.info("=" * 60)
    logger.info("--- Phase 3.5: Adding New Columns to Migrated Tables ---")
    logger.info("=" * 60)
    
    # Determine the path to column_additions.sql
    current_dir = os.path.dirname(os.path.abspath(__file__))
    project_root = os.path.dirname(current_dir)  # Go up one level from src/
    sql_file_path = os.path.join(project_root, 'reference', 'column_additions.sql')
    
    if not os.path.exists(sql_file_path):
        print(f"WARNING: Column additions SQL file not found at {sql_file_path}")
        print("Skipping column additions.")
        logger.warning(f"Column additions SQL file not found at {sql_file_path}. Skipping column additions.")
        return
    
    print(f"Reading column additions from: {sql_file_path}")
    logger.info(f"Reading column additions from: {sql_file_path}")
    
    try:
        # Read the SQL file
        with open(sql_file_path, 'r', encoding='utf-8') as f:
            sql_content = f.read()
        
        if not sql_content.strip():
            print("WARNING: Column additions SQL file is empty")
            logger.warning("Column additions SQL file is empty")
            return
        
        print(f"Executing column additions SQL script...")
        logger.info(f"Executing column additions SQL script...")
        
        # Execute the SQL script
        try:
            pg_cursor.execute(sql_content)
            print("✓ Column additions executed successfully")
            logger.info("✓ Column additions executed successfully")
            
            # Get row count if available
            if pg_cursor.rowcount >= 0:
                print(f"  Rows affected: {pg_cursor.rowcount}")
                logger.info(f"  Rows affected: {pg_cursor.rowcount}")
                
        except psycopg2.Error as e:
            print(f"✗ Error executing column additions SQL: {e}")
            print(f"  Error details: {type(e).__name__}: {str(e)}")
            logger.error(f"✗ Error executing column additions SQL: {e}")
            logger.error(f"  Error details: {type(e).__name__}: {str(e)}")
            raise
        
    except Exception as e:
        print(f"✗ Error reading or executing column additions: {e}")
        logger.error(f"✗ Error reading or executing column additions: {e}", exc_info=True)
        raise
    
    print("=" * 60)
    print("COLUMN ADDITION COMPLETE")
    print("=" * 60 + "\n")
    logger.info("=" * 60)
    logger.info("Column additions complete")
    logger.info("=" * 60)

