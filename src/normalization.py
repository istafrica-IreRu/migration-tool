"""
Data normalization utilities for extracting lookup tables and transforming data.
"""
import logging
from typing import Dict, List, Any, Set, Tuple, Optional
import psycopg2
from psycopg2 import extras

logger = logging.getLogger(__name__)


class NormalizationEngine:
    """Engine for performing data normalization operations."""

    def __init__(self, pg_conn: psycopg2.extensions.connection):
        """
        Initialize normalization engine.
        
        Args:
            pg_conn: PostgreSQL database connection
        """
        self.pg_conn = pg_conn

    def extract_lookup_table(
        self,
        source_table: str,
        source_column: str,
        lookup_table_name: str,
        lookup_id_column: str = "ID",
        lookup_value_column: str = "Value",
        create_fk: bool = True
    ) -> int:
        """
        Extract unique values from a column into a lookup table.
        
        Args:
            source_table: Source table name (schema.table format)
            source_column: Column to extract values from
            lookup_table_name: Name for the new lookup table
            lookup_id_column: Name for the ID column in lookup table
            lookup_value_column: Name for the value column in lookup table
            create_fk: Whether to create foreign key relationship
            
        Returns:
            Number of unique values extracted
        """
        cursor = self.pg_conn.cursor()
        
        try:
            # Extract schema and table name
            if '.' in source_table:
                schema, table = source_table.split('.', 1)
                schema = schema.strip('"')
                table = table.strip('"')
            else:
                schema = 'public'
                table = source_table.strip('"')
            
            full_source_table = f'"{schema}"."{table}"'
            full_lookup_table = f'"{schema}"."{lookup_table_name}"'
            
            logger.info(f"Extracting lookup table {lookup_table_name} from {source_table}.{source_column}")
            
            # Create lookup table
            create_sql = f"""
            CREATE TABLE IF NOT EXISTS {full_lookup_table} (
                "{lookup_id_column}" SERIAL PRIMARY KEY,
                "{lookup_value_column}" VARCHAR(255) UNIQUE NOT NULL,
                "CreatedAt" TIMESTAMP DEFAULT NOW()
            );
            """
            cursor.execute(create_sql)
            
            # Insert unique values
            insert_sql = f"""
            INSERT INTO {full_lookup_table} ("{lookup_value_column}")
            SELECT DISTINCT "{source_column}"
            FROM {full_source_table}
            WHERE "{source_column}" IS NOT NULL
            ON CONFLICT ("{lookup_value_column}") DO NOTHING;
            """
            cursor.execute(insert_sql)
            
            # Get count of inserted values
            cursor.execute(f'SELECT COUNT(*) FROM {full_lookup_table}')
            count = cursor.fetchone()[0]
            
            # Add new FK column to source table
            fk_column_name = f"{source_column}ID"
            alter_sql = f"""
            ALTER TABLE {full_source_table}
            ADD COLUMN IF NOT EXISTS "{fk_column_name}" INTEGER;
            """
            cursor.execute(alter_sql)
            
            # Update FK column with lookup IDs
            update_sql = f"""
            UPDATE {full_source_table} AS src
            SET "{fk_column_name}" = lkp."{lookup_id_column}"
            FROM {full_lookup_table} AS lkp
            WHERE src."{source_column}" = lkp."{lookup_value_column}";
            """
            cursor.execute(update_sql)
            
            # Create foreign key constraint if requested
            if create_fk:
                fk_name = f"fk_{table}_{lookup_table_name}"
                fk_sql = f"""
                ALTER TABLE {full_source_table}
                ADD CONSTRAINT "{fk_name}"
                FOREIGN KEY ("{fk_column_name}")
                REFERENCES {full_lookup_table} ("{lookup_id_column}");
                """
                try:
                    cursor.execute(fk_sql)
                except psycopg2.Error as e:
                    logger.warning(f"Could not create FK constraint: {e}")
            
            self.pg_conn.commit()
            logger.info(f"Successfully extracted {count} unique values into {lookup_table_name}")
            
            return count
            
        except psycopg2.Error as e:
            logger.error(f"Error extracting lookup table: {e}")
            self.pg_conn.rollback()
            raise
        finally:
            cursor.close()

    def split_column(
        self,
        table_name: str,
        source_column: str,
        target_columns: List[str],
        delimiter: str = ' ',
        max_splits: int = -1
    ) -> None:
        """
        Split a column into multiple columns.
        
        Args:
            table_name: Table name (schema.table format)
            source_column: Column to split
            target_columns: List of target column names
            delimiter: Delimiter to split on
            max_splits: Maximum number of splits (-1 for unlimited)
        """
        cursor = self.pg_conn.cursor()
        
        try:
            logger.info(f"Splitting column {source_column} in {table_name}")
            
            # Add target columns if they don't exist
            for col in target_columns:
                alter_sql = f"""
                ALTER TABLE {table_name}
                ADD COLUMN IF NOT EXISTS "{col}" VARCHAR(255);
                """
                cursor.execute(alter_sql)
            
            # Build update SQL using PostgreSQL string functions
            # This is a simplified version - for production, you'd want more robust splitting
            if len(target_columns) >= 1:
                update_sql = f"""
                UPDATE {table_name}
                SET "{target_columns[0]}" = split_part("{source_column}", '{delimiter}', 1)
                """
                if len(target_columns) >= 2:
                    update_sql += f', "{target_columns[1]}" = split_part("{source_column}", \'{delimiter}\', 2)'
                if len(target_columns) >= 3:
                    update_sql += f', "{target_columns[2]}" = split_part("{source_column}", \'{delimiter}\', 3)'
                
                cursor.execute(update_sql)
            
            self.pg_conn.commit()
            logger.info(f"Successfully split column {source_column}")
            
        except psycopg2.Error as e:
            logger.error(f"Error splitting column: {e}")
            self.pg_conn.rollback()
            raise
        finally:
            cursor.close()

    def combine_columns(
        self,
        table_name: str,
        source_columns: List[str],
        target_column: str,
        separator: str = ' ',
        drop_source: bool = False
    ) -> None:
        """
        Combine multiple columns into a single column.
        
        Args:
            table_name: Table name (schema.table format)
            source_columns: List of columns to combine
            target_column: Target column name
            separator: Separator to use when combining
            drop_source: Whether to drop source columns after combining
        """
        cursor = self.pg_conn.cursor()
        
        try:
            logger.info(f"Combining columns {source_columns} in {table_name}")
            
            # Add target column if it doesn't exist
            alter_sql = f"""
            ALTER TABLE {table_name}
            ADD COLUMN IF NOT EXISTS "{target_column}" TEXT;
            """
            cursor.execute(alter_sql)
            
            # Build CONCAT expression
            concat_parts = [f'COALESCE("{col}", \'\')' for col in source_columns]
            concat_expr = f" || '{separator}' || ".join(concat_parts)
            
            # Update target column
            update_sql = f"""
            UPDATE {table_name}
            SET "{target_column}" = {concat_expr};
            """
            cursor.execute(update_sql)
            
            # Drop source columns if requested
            if drop_source:
                for col in source_columns:
                    drop_sql = f'ALTER TABLE {table_name} DROP COLUMN IF EXISTS "{col}";'
                    cursor.execute(drop_sql)
            
            self.pg_conn.commit()
            logger.info(f"Successfully combined columns into {target_column}")
            
        except psycopg2.Error as e:
            logger.error(f"Error combining columns: {e}")
            self.pg_conn.rollback()
            raise
        finally:
            cursor.close()

    def add_audit_columns(
        self,
        table_name: str,
        created_at_column: str = "CreatedAt",
        updated_at_column: str = "UpdatedAt",
        created_by_column: Optional[str] = None,
        updated_by_column: Optional[str] = None
    ) -> None:
        """
        Add audit columns to a table.
        
        Args:
            table_name: Table name (schema.table format)
            created_at_column: Name for created timestamp column
            updated_at_column: Name for updated timestamp column
            created_by_column: Optional name for created by user column
            updated_by_column: Optional name for updated by user column
        """
        cursor = self.pg_conn.cursor()
        
        try:
            logger.info(f"Adding audit columns to {table_name}")
            
            # Add timestamp columns
            alter_sql = f"""
            ALTER TABLE {table_name}
            ADD COLUMN IF NOT EXISTS "{created_at_column}" TIMESTAMP DEFAULT NOW(),
            ADD COLUMN IF NOT EXISTS "{updated_at_column}" TIMESTAMP DEFAULT NOW();
            """
            cursor.execute(alter_sql)
            
            # Add user columns if specified
            if created_by_column:
                cursor.execute(f"""
                    ALTER TABLE {table_name}
                    ADD COLUMN IF NOT EXISTS "{created_by_column}" VARCHAR(100);
                """)
            
            if updated_by_column:
                cursor.execute(f"""
                    ALTER TABLE {table_name}
                    ADD COLUMN IF NOT EXISTS "{updated_by_column}" VARCHAR(100);
                """)
            
            self.pg_conn.commit()
            logger.info(f"Successfully added audit columns to {table_name}")
            
        except psycopg2.Error as e:
            logger.error(f"Error adding audit columns: {e}")
            self.pg_conn.rollback()
            raise
        finally:
            cursor.close()
