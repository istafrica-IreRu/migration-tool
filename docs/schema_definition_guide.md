# Schema Definition Guide

This guide explains how to use schema definitions to customize your database migration.

## Overview

Schema definitions allow you to:
- Add new columns to migrated tables
- Transform existing columns
- Extract lookup tables from repeated values
- Apply custom normalization rules

## File Format

Schema definitions are JSON files with the following structure:

```json
{
  "TableName": {
    "new_columns": [...],
    "transformations": [...],
    "skip_migration": false,
    "custom_query": null
  }
}
```

## Adding New Columns

Add columns that don't exist in the source database:

```json
{
  "Students": {
    "new_columns": [
      {
        "name": "CreatedAt",
        "type": "TIMESTAMP",
        "nullable": false,
        "default": "NOW()",
        "description": "Timestamp when record was created"
      },
      {
        "name": "UpdatedAt",
        "type": "TIMESTAMP",
        "nullable": false,
        "default": "NOW()"
      },
      {
        "name": "IsActive",
        "type": "BOOLEAN",
        "nullable": false,
        "default": "true"
      }
    ]
  }
}
```

### Column Properties

- **name** (required): Column name
- **type** (required): PostgreSQL data type (e.g., `INTEGER`, `VARCHAR(255)`, `TIMESTAMP`)
- **nullable** (optional, default: true): Whether column accepts NULL values
- **default** (optional): Default value expression
- **description** (optional): Column description for documentation

## Column Transformations

Transform data during or after migration:

### Lookup Table Extraction

Extract repeated values into a separate lookup table:

```json
{
  "Students": {
    "transformations": [
      {
        "type": "lookup_extraction",
        "source_column": "Status",
        "target_column": "StatusID",
        "lookup_table": "StudentStatus",
        "parameters": {
          "create_fk": true
        }
      }
    ]
  }
}
```

This will:
1. Create a new table `StudentStatus` with columns `ID` and `Value`
2. Populate it with unique values from `Students.Status`
3. Add a new column `Students.StatusID` as a foreign key
4. Update `Students.StatusID` with the corresponding lookup IDs

### Other Transformation Types

```json
{
  "type": "split",
  "source_column": "FullName",
  "target_columns": ["FirstName", "LastName"],
  "delimiter": " "
}
```

```json
{
  "type": "combine",
  "source_columns": ["Street", "City", "PostalCode"],
  "target_column": "FullAddress",
  "separator": ", "
}
```

## Complete Example

```json
{
  "Students": {
    "new_columns": [
      {
        "name": "CreatedAt",
        "type": "TIMESTAMP",
        "nullable": false,
        "default": "NOW()"
      },
      {
        "name": "UpdatedAt",
        "type": "TIMESTAMP",
        "nullable": false,
        "default": "NOW()"
      },
      {
        "name": "IsActive",
        "type": "BOOLEAN",
        "nullable": false,
        "default": "true"
      },
      {
        "name": "Notes",
        "type": "TEXT",
        "nullable": true
      }
    ],
    "transformations": [
      {
        "type": "lookup_extraction",
        "source_column": "Status",
        "target_column": "StatusID",
        "lookup_table": "StudentStatus",
        "parameters": {
          "create_fk": true
        }
      },
      {
        "type": "lookup_extraction",
        "source_column": "Gender",
        "target_column": "GenderID",
        "lookup_table": "Gender",
        "parameters": {
          "create_fk": true
        }
      }
    ]
  },
  "Teachers": {
    "new_columns": [
      {
        "name": "CreatedAt",
        "type": "TIMESTAMP",
        "nullable": false,
        "default": "NOW()"
      },
      {
        "name": "UpdatedAt",
        "type": "TIMESTAMP",
        "nullable": false,
        "default": "NOW()"
      }
    ]
  },
  "Classes": {
    "new_columns": [
      {
        "name": "CreatedAt",
        "type": "TIMESTAMP",
        "nullable": false,
        "default": "NOW()"
      }
    ],
    "skip_migration": false
  }
}
```

## Usage

Run the migration with your schema definition:

```bash
python migrate_enhanced.py \
  --translations-file resources/translations.json \
  --schema-definition resources/schema_definition.json
```

## Best Practices

1. **Start Simple**: Begin with just adding audit columns (CreatedAt, UpdatedAt)
2. **Test Incrementally**: Test each transformation separately before combining
3. **Backup First**: Always backup your data before running transformations
4. **Document Changes**: Use the description field to document why columns were added
5. **Validate Results**: Use `--validate-only` to check data quality before migration

## Common Patterns

### Audit Columns

Add to all tables:

```json
{
  "CreatedAt": {
    "type": "TIMESTAMP",
    "nullable": false,
    "default": "NOW()"
  },
  "UpdatedAt": {
    "type": "TIMESTAMP",
    "nullable": false,
    "default": "NOW()"
  },
  "CreatedBy": {
    "type": "VARCHAR(100)",
    "nullable": true
  },
  "UpdatedBy": {
    "type": "VARCHAR(100)",
    "nullable": true
  }
}
```

### Soft Delete

```json
{
  "IsDeleted": {
    "type": "BOOLEAN",
    "nullable": false,
    "default": "false"
  },
  "DeletedAt": {
    "type": "TIMESTAMP",
    "nullable": true
  }
}
```

### Status Normalization

```json
{
  "transformations": [
    {
      "type": "lookup_extraction",
      "source_column": "Status",
      "target_column": "StatusID",
      "lookup_table": "StatusLookup"
    }
  ]
}
```
