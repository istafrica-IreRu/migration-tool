#!/usr/bin/env python3
"""
Diagnostic test script to verify column addition functionality.
Tests the add_new_columns_to_tables function directly.
"""
import sys
import os

# Add src directory to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'src'))

from config import load_config
from main import get_pg_connection
from column_additions import add_new_columns_to_tables
import logging

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)

logger = logging.getLogger(__name__)


def check_column_exists(cursor, table_name, column_name):
    """Check if a column exists in a table."""
    cursor.execute("""
        SELECT column_name, data_type, is_nullable
        FROM information_schema.columns
        WHERE table_schema = 'public'
        AND table_name = %s
        AND column_name = %s
    """, (table_name, column_name))
    
    result = cursor.fetchone()
    return result is not None, result


def main():
    print("=" * 60)
    print("Column Addition Diagnostic Test")
    print("=" * 60)
    
    try:
        # Connect to PostgreSQL
        logger.info("Connecting to PostgreSQL...")
        pg_conn = get_pg_connection()
        pg_cursor = pg_conn.cursor()
        logger.info("✓ Connected successfully")
        
        # Check if ApplicantTable exists
        logger.info("Checking if ApplicantTable exists...")
        pg_cursor.execute("""
            SELECT table_name
            FROM information_schema.tables
            WHERE table_schema = 'public'
            AND table_name = 'ApplicantTable'
        """)
        
        if not pg_cursor.fetchone():
            logger.warning("⚠ ApplicantTable does not exist in the database")
            logger.info("This table should be created during Phase 1 migration")
            print("\n" + "=" * 60)
            print("RESULT: ApplicantTable not found")
            print("Please run Phase 1 migration first")
            print("=" * 60)
            return
        
        logger.info("✓ ApplicantTable exists")
        
        # Check if UserID column exists BEFORE adding
        logger.info("Checking if UserID column exists before addition...")
        exists_before, col_info = check_column_exists(pg_cursor, 'ApplicantTable', 'UserID')
        
        if exists_before:
            logger.info(f"✓ UserID column already exists: {col_info}")
            print("\n" + "=" * 60)
            print("RESULT: UserID column already exists")
            print(f"  Data Type: {col_info[1]}")
            print(f"  Nullable: {col_info[2]}")
            print("=" * 60)
        else:
            logger.info("✗ UserID column does not exist")
            
            # Try to add the column
            logger.info("Attempting to add new columns...")
            pg_conn.autocommit = False
            
            try:
                add_new_columns_to_tables(pg_cursor)
                pg_conn.commit()
                logger.info("✓ Column addition completed and committed")
            except Exception as e:
                logger.error(f"✗ Error during column addition: {e}")
                pg_conn.rollback()
                raise
            
            # Check if UserID column exists AFTER adding
            logger.info("Checking if UserID column exists after addition...")
            exists_after, col_info = check_column_exists(pg_cursor, 'ApplicantTable', 'UserID')
            
            if exists_after:
                logger.info(f"✓ UserID column successfully added: {col_info}")
                print("\n" + "=" * 60)
                print("SUCCESS: UserID column added successfully")
                print(f"  Data Type: {col_info[1]}")
                print(f"  Nullable: {col_info[2]}")
                print("=" * 60)
            else:
                logger.error("✗ UserID column was NOT added")
                print("\n" + "=" * 60)
                print("FAILURE: UserID column was not added")
                print("Check the logs above for errors")
                print("=" * 60)
        
        # List all columns in ApplicantTable
        logger.info("Listing all columns in ApplicantTable...")
        pg_cursor.execute("""
            SELECT column_name, data_type, is_nullable
            FROM information_schema.columns
            WHERE table_schema = 'public'
            AND table_name = 'ApplicantTable'
            ORDER BY ordinal_position
        """)
        
        columns = pg_cursor.fetchall()
        print("\nAll columns in ApplicantTable:")
        print("-" * 60)
        for col in columns:
            nullable_str = "NULL" if col[2] == 'YES' else "NOT NULL"
            print(f"  {col[0]:<30} {col[1]:<20} {nullable_str}")
        print("-" * 60)
        
        pg_cursor.close()
        pg_conn.close()
        
    except Exception as e:
        logger.error(f"Test failed with error: {e}", exc_info=True)
        print("\n" + "=" * 60)
        print(f"ERROR: {e}")
        print("=" * 60)
        sys.exit(1)


if __name__ == "__main__":
    main()
