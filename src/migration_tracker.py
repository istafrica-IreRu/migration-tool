"""
Migration tracking system to record which normalization scripts have been applied.
"""
import logging
import hashlib
from typing import List, Optional
from datetime import datetime
import psycopg2

logger = logging.getLogger(__name__)


class MigrationTracker:
    """Tracks migration script execution to prevent duplicates and support rollback."""

    TRACKING_TABLE = "migration_history"

    def __init__(self, pg_conn: psycopg2.extensions.connection):
        """
        Initialize migration tracker.
        
        Args:
            pg_conn: PostgreSQL database connection
        """
        self.pg_conn = pg_conn
        self._ensure_tracking_table()

    def _ensure_tracking_table(self) -> None:
        """Create migration tracking table if it doesn't exist."""
        cursor = self.pg_conn.cursor()
        
        try:
            create_sql = f"""
            CREATE TABLE IF NOT EXISTS {self.TRACKING_TABLE} (
                id SERIAL PRIMARY KEY,
                script_name VARCHAR(255) NOT NULL UNIQUE,
                script_type VARCHAR(50) NOT NULL,
                checksum VARCHAR(64) NOT NULL,
                executed_at TIMESTAMP DEFAULT NOW(),
                execution_time_ms INTEGER,
                success BOOLEAN DEFAULT TRUE,
                error_message TEXT,
                rollback_script TEXT
            );
            
            CREATE INDEX IF NOT EXISTS idx_migration_history_script_name 
            ON {self.TRACKING_TABLE}(script_name);
            
            CREATE INDEX IF NOT EXISTS idx_migration_history_executed_at 
            ON {self.TRACKING_TABLE}(executed_at);
            """
            cursor.execute(create_sql)
            self.pg_conn.commit()
            logger.debug("Migration tracking table ensured")
            
        except psycopg2.Error as e:
            logger.error(f"Error creating tracking table: {e}")
            self.pg_conn.rollback()
            raise
        finally:
            cursor.close()

    def _calculate_checksum(self, content: str) -> str:
        """Calculate SHA-256 checksum of script content."""
        return hashlib.sha256(content.encode('utf-8')).hexdigest()

    def is_script_executed(self, script_name: str) -> bool:
        """
        Check if a script has already been executed.
        
        Args:
            script_name: Name of the script
            
        Returns:
            True if script has been executed successfully
        """
        cursor = self.pg_conn.cursor()
        
        try:
            cursor.execute(
                f"""
                SELECT COUNT(*) FROM {self.TRACKING_TABLE}
                WHERE script_name = %s AND success = TRUE
                """,
                (script_name,)
            )
            count = cursor.fetchone()[0]
            return count > 0
            
        finally:
            cursor.close()

    def record_execution(
        self,
        script_name: str,
        script_type: str,
        content: str,
        execution_time_ms: int,
        success: bool = True,
        error_message: Optional[str] = None,
        rollback_script: Optional[str] = None
    ) -> None:
        """
        Record script execution in tracking table.
        
        Args:
            script_name: Name of the script
            script_type: Type of script (e.g., 'normalization', 'migration')
            content: Script content for checksum calculation
            execution_time_ms: Execution time in milliseconds
            success: Whether execution was successful
            error_message: Error message if execution failed
            rollback_script: Optional rollback script
        """
        cursor = self.pg_conn.cursor()
        
        try:
            checksum = self._calculate_checksum(content)
            
            insert_sql = f"""
            INSERT INTO {self.TRACKING_TABLE} 
            (script_name, script_type, checksum, execution_time_ms, success, error_message, rollback_script)
            VALUES (%s, %s, %s, %s, %s, %s, %s)
            ON CONFLICT (script_name) DO UPDATE
            SET checksum = EXCLUDED.checksum,
                executed_at = NOW(),
                execution_time_ms = EXCLUDED.execution_time_ms,
                success = EXCLUDED.success,
                error_message = EXCLUDED.error_message,
                rollback_script = EXCLUDED.rollback_script;
            """
            
            cursor.execute(
                insert_sql,
                (script_name, script_type, checksum, execution_time_ms, success, error_message, rollback_script)
            )
            self.pg_conn.commit()
            
            logger.info(f"Recorded execution of {script_name} (success: {success})")
            
        except psycopg2.Error as e:
            logger.error(f"Error recording script execution: {e}")
            self.pg_conn.rollback()
            raise
        finally:
            cursor.close()

    def get_execution_history(self, limit: int = 100) -> List[dict]:
        """
        Get execution history.
        
        Args:
            limit: Maximum number of records to return
            
        Returns:
            List of execution records
        """
        cursor = self.pg_conn.cursor()
        
        try:
            cursor.execute(
                f"""
                SELECT script_name, script_type, executed_at, execution_time_ms, success, error_message
                FROM {self.TRACKING_TABLE}
                ORDER BY executed_at DESC
                LIMIT %s
                """,
                (limit,)
            )
            
            columns = ['script_name', 'script_type', 'executed_at', 'execution_time_ms', 'success', 'error_message']
            results = []
            
            for row in cursor.fetchall():
                results.append(dict(zip(columns, row)))
            
            return results
            
        finally:
            cursor.close()

    def verify_checksum(self, script_name: str, content: str) -> bool:
        """
        Verify if script content matches recorded checksum.
        
        Args:
            script_name: Name of the script
            content: Current script content
            
        Returns:
            True if checksum matches or script not executed yet
        """
        cursor = self.pg_conn.cursor()
        
        try:
            cursor.execute(
                f"""
                SELECT checksum FROM {self.TRACKING_TABLE}
                WHERE script_name = %s
                """,
                (script_name,)
            )
            
            result = cursor.fetchone()
            if not result:
                return True  # Script not executed yet
            
            stored_checksum = result[0]
            current_checksum = self._calculate_checksum(content)
            
            if stored_checksum != current_checksum:
                logger.warning(
                    f"Checksum mismatch for {script_name}. "
                    f"Script may have been modified after execution."
                )
                return False
            
            return True
            
        finally:
            cursor.close()

    def get_pending_scripts(self, all_scripts: List[str]) -> List[str]:
        """
        Get list of scripts that haven't been executed yet.
        
        Args:
            all_scripts: List of all available script names
            
        Returns:
            List of pending script names
        """
        cursor = self.pg_conn.cursor()
        
        try:
            cursor.execute(
                f"""
                SELECT script_name FROM {self.TRACKING_TABLE}
                WHERE success = TRUE
                """
            )
            
            executed = {row[0] for row in cursor.fetchall()}
            pending = [s for s in all_scripts if s not in executed]
            
            return pending
            
        finally:
            cursor.close()
