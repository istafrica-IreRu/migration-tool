"""
Schema definition manager for handling custom schema definitions.
Supports adding new columns, transformations, and normalization rules.
"""
import json
import logging
from typing import Dict, List, Any, Optional
from dataclasses import dataclass
from enum import Enum

logger = logging.getLogger(__name__)


class TransformationType(Enum):
    """Types of column transformations."""
    LOOKUP_EXTRACTION = "lookup_extraction"
    COMPUTED = "computed"
    SPLIT = "split"
    COMBINE = "combine"
    RENAME = "rename"


@dataclass
class NewColumn:
    """Definition for a new column to add to a table."""
    name: str
    type: str
    nullable: bool = True
    default: Optional[str] = None
    description: Optional[str] = None

    def to_sql_definition(self) -> str:
        """Generate SQL column definition."""
        parts = [f'"{self.name}" {self.type}']
        
        if not self.nullable:
            parts.append("NOT NULL")
        
        if self.default:
            parts.append(f"DEFAULT {self.default}")
        
        return " ".join(parts)


@dataclass
class ColumnTransformation:
    """Definition for a column transformation."""
    type: TransformationType
    source_column: Optional[str] = None
    target_column: Optional[str] = None
    lookup_table: Optional[str] = None
    expression: Optional[str] = None
    parameters: Optional[Dict[str, Any]] = None

    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> 'ColumnTransformation':
        """Create transformation from dictionary."""
        trans_type = TransformationType(data.get('type'))
        return cls(
            type=trans_type,
            source_column=data.get('source_column'),
            target_column=data.get('target_column'),
            lookup_table=data.get('lookup_table'),
            expression=data.get('expression'),
            parameters=data.get('parameters', {})
        )


@dataclass
class TableDefinition:
    """Definition for table customizations."""
    table_name: str
    new_columns: List[NewColumn]
    transformations: List[ColumnTransformation]
    skip_migration: bool = False
    custom_query: Optional[str] = None

    @classmethod
    def from_dict(cls, table_name: str, data: Dict[str, Any]) -> 'TableDefinition':
        """Create table definition from dictionary."""
        # Parse new columns
        new_columns = []
        for col_data in data.get('new_columns', []):
            new_columns.append(NewColumn(
                name=col_data['name'],
                type=col_data['type'],
                nullable=col_data.get('nullable', True),
                default=col_data.get('default'),
                description=col_data.get('description')
            ))
        
        # Parse transformations
        transformations = []
        for trans_data in data.get('transformations', []):
            transformations.append(ColumnTransformation.from_dict(trans_data))
        
        return cls(
            table_name=table_name,
            new_columns=new_columns,
            transformations=transformations,
            skip_migration=data.get('skip_migration', False),
            custom_query=data.get('custom_query')
        )


class SchemaManager:
    """Manages schema definitions and applies customizations."""

    def __init__(self, schema_file_path: Optional[str] = None):
        """
        Initialize schema manager.
        
        Args:
            schema_file_path: Path to schema definition JSON file
        """
        self.schema_file_path = schema_file_path
        self.table_definitions: Dict[str, TableDefinition] = {}
        
        if schema_file_path:
            self.load_schema_definition(schema_file_path)

    def load_schema_definition(self, file_path: str) -> None:
        """
        Load schema definition from JSON file.
        
        Args:
            file_path: Path to schema definition file
        """
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                schema_data = json.load(f)
            
            # Parse table definitions
            for table_name, table_data in schema_data.items():
                self.table_definitions[table_name] = TableDefinition.from_dict(
                    table_name, table_data
                )
            
            logger.info(f"Loaded schema definitions for {len(self.table_definitions)} tables")
            
        except FileNotFoundError:
            logger.warning(f"Schema definition file not found: {file_path}")
        except json.JSONDecodeError as e:
            logger.error(f"Error parsing schema definition file: {e}")
            raise
        except Exception as e:
            logger.error(f"Error loading schema definition: {e}")
            raise

    def get_table_definition(self, table_name: str) -> Optional[TableDefinition]:
        """
        Get table definition for a specific table.
        
        Args:
            table_name: Name of the table (translated name)
            
        Returns:
            TableDefinition if exists, None otherwise
        """
        return self.table_definitions.get(table_name)

    def has_customizations(self, table_name: str) -> bool:
        """
        Check if a table has any customizations defined.
        
        Args:
            table_name: Name of the table
            
        Returns:
            True if customizations exist
        """
        return table_name in self.table_definitions

    def get_new_columns(self, table_name: str) -> List[NewColumn]:
        """
        Get list of new columns to add to a table.
        
        Args:
            table_name: Name of the table
            
        Returns:
            List of NewColumn objects
        """
        table_def = self.get_table_definition(table_name)
        return table_def.new_columns if table_def else []

    def get_transformations(self, table_name: str) -> List[ColumnTransformation]:
        """
        Get list of transformations for a table.
        
        Args:
            table_name: Name of the table
            
        Returns:
            List of ColumnTransformation objects
        """
        table_def = self.get_table_definition(table_name)
        return table_def.transformations if table_def else []

    def should_skip_table(self, table_name: str) -> bool:
        """
        Check if a table should be skipped during migration.
        
        Args:
            table_name: Name of the table
            
        Returns:
            True if table should be skipped
        """
        table_def = self.get_table_definition(table_name)
        return table_def.skip_migration if table_def else False

    def get_lookup_extractions(self, table_name: str) -> List[ColumnTransformation]:
        """
        Get all lookup extraction transformations for a table.
        
        Args:
            table_name: Name of the table
            
        Returns:
            List of lookup extraction transformations
        """
        transformations = self.get_transformations(table_name)
        return [
            t for t in transformations 
            if t.type == TransformationType.LOOKUP_EXTRACTION
        ]

    def generate_summary(self) -> str:
        """
        Generate a summary of all schema customizations.
        
        Returns:
            Summary string
        """
        if not self.table_definitions:
            return "No schema customizations defined."
        
        lines = ["Schema Customizations Summary:", ""]
        
        for table_name, table_def in self.table_definitions.items():
            lines.append(f"Table: {table_name}")
            
            if table_def.skip_migration:
                lines.append("  - SKIPPED (will not be migrated)")
            
            if table_def.new_columns:
                lines.append(f"  New Columns ({len(table_def.new_columns)}):")
                for col in table_def.new_columns:
                    lines.append(f"    - {col.name} ({col.type})")
            
            if table_def.transformations:
                lines.append(f"  Transformations ({len(table_def.transformations)}):")
                for trans in table_def.transformations:
                    if trans.type == TransformationType.LOOKUP_EXTRACTION:
                        lines.append(
                            f"    - Extract lookup: {trans.source_column} -> "
                            f"{trans.lookup_table}.{trans.target_column}"
                        )
                    else:
                        lines.append(f"    - {trans.type.value}: {trans.source_column}")
            
            lines.append("")
        
        return "\n".join(lines)
