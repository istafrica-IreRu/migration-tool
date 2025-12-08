"""
Configuration management for the migration script.
Loads settings from environment variables and provides validation.
"""
import os
from typing import List, Optional
from dataclasses import dataclass
from dotenv import load_dotenv
import logging

# Load environment variables from .env file
load_dotenv()

logger = logging.getLogger(__name__)


@dataclass
class MSSQLConfig:
    """MSSQL database configuration."""
    server: str
    database: str
    username: str
    password: str
    trusted_connection: bool = False

    def get_connection_string(self) -> str:
        """Generate ODBC connection string."""
        conn_str = (
            f"DRIVER={{ODBC Driver 17 for SQL Server}};"
            f"SERVER={self.server};"
            f"DATABASE={self.database};"
        )
        
        if self.trusted_connection:
            conn_str += "Trusted_Connection=yes;"
        else:
            conn_str += f"UID={self.username};PWD={self.password};"
            
        return conn_str


@dataclass
class PostgreSQLConfig:
    """PostgreSQL database configuration."""
    host: str
    database: str
    user: str
    password: str
    port: str

    def get_connection_params(self) -> dict:
        """Get connection parameters as dictionary."""
        return {
            'host': self.host,
            'database': self.database,
            'user': self.user,
            'password': self.password,
            'port': self.port
        }


@dataclass
class MigrationConfig:
    """Migration-specific configuration."""
    schemas_to_migrate: List[str]
    config_profile: str = 'dev'


class Config:
    """Main configuration class that loads and validates all settings."""

    def __init__(self):
        """Initialize configuration from environment variables."""
        self.mssql = self._load_mssql_config()
        self.postgresql = self._load_postgresql_config()
        self.migration = self._load_migration_config()
        self._validate()

    def _load_mssql_config(self) -> MSSQLConfig:
        """Load MSSQL configuration from environment."""
        return MSSQLConfig(
            server=os.getenv('MSSQL_SERVER', 'localhost'),
            database=os.getenv('MSSQL_DATABASE', 'wsdata'),
            username=os.getenv('MSSQL_USERNAME', ''),
            password=os.getenv('MSSQL_PASSWORD', ''),
            trusted_connection=os.getenv('MSSQL_TRUSTED_CONNECTION', 'false').lower() == 'true'
        )

    def _load_postgresql_config(self) -> PostgreSQLConfig:
        """Load PostgreSQL configuration from environment."""
        return PostgreSQLConfig(
            host=os.getenv('PG_HOST', 'localhost'),
            database=os.getenv('PG_DATABASE', 'wsdata_v4'),
            user=os.getenv('PG_USER', 'postgres'),
            password=os.getenv('PG_PASSWORD', ''),
            port=os.getenv('PG_PORT', '5432')
        )

    def _load_migration_config(self) -> MigrationConfig:
        """Load migration configuration from environment."""
        schemas_str = os.getenv('SCHEMAS_TO_MIGRATE', 'dbo,winSCHOOLPlus')
        schemas = [s.strip() for s in schemas_str.split(',') if s.strip()]
        
        return MigrationConfig(
            schemas_to_migrate=schemas,
            config_profile=os.getenv('CONFIG_PROFILE', 'dev')
        )

    def _validate(self) -> None:
        """Validate configuration settings."""
        errors = []

        # Validate MSSQL config
        if not self.mssql.server:
            errors.append("MSSQL_SERVER is required")
        if not self.mssql.database:
            errors.append("MSSQL_DATABASE is required")
            
        if not self.mssql.trusted_connection:
            if not self.mssql.username:
                errors.append("MSSQL_USERNAME is required (or use MSSQL_TRUSTED_CONNECTION=true)")
            if not self.mssql.password:
                logger.warning("MSSQL_PASSWORD is empty - this may cause connection issues")

        # Validate PostgreSQL config
        if not self.postgresql.host:
            errors.append("PG_HOST is required")
        if not self.postgresql.database:
            errors.append("PG_DATABASE is required")
        if not self.postgresql.user:
            errors.append("PG_USER is required")
        if not self.postgresql.password:
            logger.warning("PG_PASSWORD is empty - this may cause connection issues")

        # Validate migration config
        if not self.migration.schemas_to_migrate:
            errors.append("SCHEMAS_TO_MIGRATE must contain at least one schema")

        if errors:
            error_msg = "Configuration validation failed:\n" + "\n".join(f"  - {e}" for e in errors)
            raise ValueError(error_msg)

        logger.info(f"Configuration loaded successfully (profile: {self.migration.config_profile})")
        logger.info(f"Schemas to migrate: {', '.join(self.migration.schemas_to_migrate)}")

    def display_summary(self) -> str:
        """Generate a summary of the configuration (without passwords)."""
        return f"""
Configuration Summary:
  Profile: {self.migration.config_profile}
  
  MSSQL:
    Server: {self.mssql.server}
    Database: {self.mssql.database}
    Username: {self.mssql.username}
    Password: {'*' * len(self.mssql.password) if self.mssql.password else '(empty)'}
  
  PostgreSQL:
    Host: {self.postgresql.host}
    Port: {self.postgresql.port}
    Database: {self.postgresql.database}
    User: {self.postgresql.user}
    Password: {'*' * len(self.postgresql.password) if self.postgresql.password else '(empty)'}
  
  Migration:
    Schemas: {', '.join(self.migration.schemas_to_migrate)}
"""


def load_config() -> Config:
    """
    Load and return the configuration.
    This is the main entry point for getting configuration.
    """
    return Config()
