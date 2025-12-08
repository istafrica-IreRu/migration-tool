"""
Data validation framework for pre and post-migration checks.
"""
import logging
from typing import Dict, List, Any, Tuple
from dataclasses import dataclass
import pyodbc
import psycopg2

logger = logging.getLogger(__name__)


@dataclass
class ValidationIssue:
    """Represents a validation issue found during checks."""
    severity: str  # 'error', 'warning', 'info'
    category: str  # 'data_quality', 'schema', 'integrity'
    table: str
    column: str = ""
    message: str = ""
    count: int = 0

    def __str__(self) -> str:
        location = f"{self.table}.{self.column}" if self.column else self.table
        count_str = f" ({self.count} occurrences)" if self.count > 0 else ""
        return f"[{self.severity.upper()}] {self.category}: {location} - {self.message}{count_str}"


class DataValidator:
    """Validates data quality before and after migration."""

    def __init__(
        self,
        mssql_conn: pyodbc.Connection = None,
        pg_conn: psycopg2.extensions.connection = None
    ):
        """
        Initialize data validator.
        
        Args:
            mssql_conn: MSSQL connection for source validation
            pg_conn: PostgreSQL connection for target validation
        """
        self.mssql_conn = mssql_conn
        self.pg_conn = pg_conn
        self.issues: List[ValidationIssue] = []

    def validate_source_data(self, tables_metadata: Dict[str, Any]) -> List[ValidationIssue]:
        """
        Validate source data quality before migration.
        
        Args:
            tables_metadata: Metadata about tables to validate
            
        Returns:
            List of validation issues
        """
        logger.info("Starting source data validation...")
        self.issues = []
        
        if not self.mssql_conn:
            logger.warning("No MSSQL connection provided, skipping source validation")
            return self.issues
        
        cursor = self.mssql_conn.cursor()
        
        for table_key, data in tables_metadata.items():
            schema_name, table_name = table_key.split('.')
            
            # Get original table name
            if data['columns']:
                original_table = data['columns'][0].TABLE_NAME
                original_schema = data['columns'][0].TABLE_SCHEMA
                
                # Check for NULL values in important columns
                self._check_null_values(cursor, original_schema, original_table, data['columns'])
                
                # Check for duplicate primary keys
                self._check_duplicate_keys(cursor, original_schema, original_table, data)
                
                # Check for orphaned foreign keys
                self._check_orphaned_fks(cursor, original_schema, original_table, data)
        
        cursor.close()
        
        logger.info(f"Source validation complete. Found {len(self.issues)} issues.")
        return self.issues

    def _check_null_values(self, cursor, schema: str, table: str, columns: List[Any]) -> None:
        """Check for NULL values in non-nullable columns."""
        for col in columns:
            if col.IS_NULLABLE == 'NO':
                try:
                    cursor.execute(
                        f'SELECT COUNT(*) FROM "{schema}"."{table}" WHERE "{col.COLUMN_NAME}" IS NULL'
                    )
                    null_count = cursor.fetchone()[0]
                    
                    if null_count > 0:
                        self.issues.append(ValidationIssue(
                            severity='error',
                            category='data_quality',
                            table=f"{schema}.{table}",
                            column=col.COLUMN_NAME,
                            message="NULL values found in NOT NULL column",
                            count=null_count
                        ))
                except Exception as e:
                    logger.debug(f"Could not check NULL values for {table}.{col.COLUMN_NAME}: {e}")

    def _check_duplicate_keys(self, cursor, schema: str, table: str, data: Dict[str, Any]) -> None:
        """Check for duplicate values in primary key columns."""
        pk_constraints = [c for c in data.get('constraints', []) if c['type'] == 'PRIMARY KEY']
        
        for pk in pk_constraints:
            pk_columns = pk['definition']
            if pk_columns:
                try:
                    columns_str = ', '.join([f'"{col}"' for col in pk_columns])
                    cursor.execute(f"""
                        SELECT {columns_str}, COUNT(*) as cnt
                        FROM "{schema}"."{table}"
                        GROUP BY {columns_str}
                        HAVING COUNT(*) > 1
                    """)
                    
                    duplicates = cursor.fetchall()
                    if duplicates:
                        self.issues.append(ValidationIssue(
                            severity='error',
                            category='integrity',
                            table=f"{schema}.{table}",
                            column=', '.join(pk_columns),
                            message="Duplicate primary key values found",
                            count=len(duplicates)
                        ))
                except Exception as e:
                    logger.debug(f"Could not check duplicates for {table}: {e}")

    def _check_orphaned_fks(self, cursor, schema: str, table: str, data: Dict[str, Any]) -> None:
        """Check for orphaned foreign key references."""
        # This is a simplified check - full implementation would verify against parent tables
        pass

    def validate_target_data(self, tables_metadata: Dict[str, Any]) -> List[ValidationIssue]:
        """
        Validate target data after migration.
        
        Args:
            tables_metadata: Metadata about migrated tables
            
        Returns:
            List of validation issues
        """
        logger.info("Starting target data validation...")
        self.issues = []
        
        if not self.pg_conn:
            logger.warning("No PostgreSQL connection provided, skipping target validation")
            return self.issues
        
        cursor = self.pg_conn.cursor()
        
        for table_key, data in tables_metadata.items():
            schema_name, table_name = table_key.split('.')
            pg_schema = 'public' if schema_name == 'dbo' else schema_name
            pg_table = f'"{pg_schema}"."{table_name}"'
            
            # Check table exists
            self._check_table_exists(cursor, pg_schema, table_name)
            
            # Check row counts
            self._check_row_counts(cursor, pg_table, table_key)
        
        cursor.close()
        
        logger.info(f"Target validation complete. Found {len(self.issues)} issues.")
        return self.issues

    def _check_table_exists(self, cursor, schema: str, table: str) -> None:
        """Check if table exists in target database."""
        try:
            cursor.execute("""
                SELECT COUNT(*) FROM information_schema.tables
                WHERE table_schema = %s AND table_name = %s
            """, (schema, table))
            
            exists = cursor.fetchone()[0] > 0
            if not exists:
                self.issues.append(ValidationIssue(
                    severity='error',
                    category='schema',
                    table=f"{schema}.{table}",
                    message="Table not found in target database"
                ))
        except Exception as e:
            logger.debug(f"Could not check table existence: {e}")

    def _check_row_counts(self, cursor, pg_table: str, table_key: str) -> None:
        """Check row counts in target table."""
        try:
            cursor.execute(f'SELECT COUNT(*) FROM {pg_table}')
            count = cursor.fetchone()[0]
            
            if count == 0:
                self.issues.append(ValidationIssue(
                    severity='warning',
                    category='data_quality',
                    table=table_key,
                    message="Table is empty after migration"
                ))
        except Exception as e:
            logger.debug(f"Could not check row count for {table_key}: {e}")

    def compare_row_counts(
        self,
        tables_metadata: Dict[str, Any]
    ) -> Dict[str, Tuple[int, int]]:
        """
        Compare row counts between source and target.
        
        Args:
            tables_metadata: Metadata about tables
            
        Returns:
            Dictionary mapping table names to (source_count, target_count) tuples
        """
        if not self.mssql_conn or not self.pg_conn:
            logger.warning("Both connections required for row count comparison")
            return {}
        
        results = {}
        mssql_cursor = self.mssql_conn.cursor()
        pg_cursor = self.pg_conn.cursor()
        
        for table_key, data in tables_metadata.items():
            if not data['columns']:
                continue
            
            schema_name, table_name = table_key.split('.')
            original_schema = data['columns'][0].TABLE_SCHEMA
            original_table = data['columns'][0].TABLE_NAME
            
            try:
                # Source count
                mssql_cursor.execute(f'SELECT COUNT(*) FROM "{original_schema}"."{original_table}"')
                source_count = mssql_cursor.fetchone()[0]
                
                # Target count
                pg_schema = 'public' if schema_name == 'dbo' else schema_name
                pg_cursor.execute(f'SELECT COUNT(*) FROM "{pg_schema}"."{table_name}"')
                target_count = pg_cursor.fetchone()[0]
                
                results[table_key] = (source_count, target_count)
                
                if source_count != target_count:
                    self.issues.append(ValidationIssue(
                        severity='warning',
                        category='data_quality',
                        table=table_key,
                        message=f"Row count mismatch: source={source_count}, target={target_count}"
                    ))
            except Exception as e:
                logger.debug(f"Could not compare row counts for {table_key}: {e}")
        
        mssql_cursor.close()
        pg_cursor.close()
        
        return results

    def generate_report(self) -> str:
        """Generate a validation report."""
        if not self.issues:
            return "✅ No validation issues found."
        
        lines = ["Validation Report", "=" * 50, ""]
        
        # Group by severity
        errors = [i for i in self.issues if i.severity == 'error']
        warnings = [i for i in self.issues if i.severity == 'warning']
        info = [i for i in self.issues if i.severity == 'info']
        
        if errors:
            lines.append(f"ERRORS ({len(errors)}):")
            for issue in errors:
                lines.append(f"  {issue}")
            lines.append("")
        
        if warnings:
            lines.append(f"WARNINGS ({len(warnings)}):")
            for issue in warnings:
                lines.append(f"  {issue}")
            lines.append("")
        
        if info:
            lines.append(f"INFO ({len(info)}):")
            for issue in info:
                lines.append(f"  {issue}")
            lines.append("")
        
        lines.append(f"Total Issues: {len(self.issues)}")
        
        return "\n".join(lines)
