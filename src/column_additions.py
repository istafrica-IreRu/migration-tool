"""
Module for adding new columns to migrated tables after Phase 1 (raw migration).
This ensures columns exist before normalization runs.
"""
import logging
import psycopg2
import os

logger = logging.getLogger(__name__)


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

