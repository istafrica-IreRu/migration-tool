# How to Add New Columns to the Migration

This guide explains how to add new columns to tables during migration using the updated `column_additions.py` module.

## ✨ Fully Automatic Process

The schema definition update happens **automatically** during migration! You just need to define which columns to add, and the system handles the rest.

## Quick Start

1. Open `src/column_additions.py`
2. Find the `NEW_COLUMNS` dictionary in the `add_new_columns_to_tables()` function
3. Add your table and column definitions
4. Run the migration via the frontend or API - **everything happens automatically!**

## When Does It Run?

During the migration process (Phase 3.5):
1. ✅ Raw migration completes (Phase 1-3)
2. ✅ **New columns are automatically added to database tables**
3. ✅ **`schema_definition.json` is automatically updated**
4. ✅ Constraints and indexes are added (Phase 4)
5. ✅ Views are migrated (Phase 5)

**No manual steps required!** The schema stays in sync automatically.

## Column Definition Format

```python
NEW_COLUMNS = {
    'schema."TableName"': [
        ('ColumnName', 'DataType', nullable, default, 'Description'),
    ],
}
```

### Parameters:
- **schema."TableName"**: Full table identifier (e.g., `'public."ApplicantProcedure"'`)
- **ColumnName**: Name of the new column (e.g., `'Status'`)
- **DataType**: PostgreSQL data type (e.g., `'SMALLINT'`, `'VARCHAR(255)'`, `'INTEGER'`)
- **nullable**: `True` if column can be NULL, `False` otherwise
- **default**: Default value as a string (e.g., `'1'`, `'6_POINT'`) or `None`
- **Description**: Human-readable description of the column

## Example

To add the columns shown in your screenshot to `ApplicantProcedure`:

```python
NEW_COLUMNS = {
    'public."ApplicantProcedure"': [
        ('Status', 'SMALLINT', False, '1', 'Status of the applicant procedure'),
        ('IsDraft', 'SMALLINT', False, '0', 'Indicates if the applicant procedure is in draft status'),
        ('GradingScale', 'VARCHAR(255)', True, '6_POINT', 'Grading scale used for the applicant procedure'),
        ('AgeLimit', 'INTEGER', True, '12', 'Age limit for the applicant procedure'),
    ],
}
```

## What Happens Automatically

When you run the migration via the frontend:

1. ✅ Columns are added to the PostgreSQL database
2. ✅ `resources/schema_definition.json` is automatically updated
3. ✅ Duplicate columns are detected and skipped
4. ✅ JSON file is properly formatted
5. ✅ Progress is shown in the frontend UI

## Monitoring

Watch the migration logs or frontend UI for:
- "Adding column 'ColumnName' to TableName"
- "Updating schema definition file..."
- "Successfully updated schema definition file"

## Notes

- The schema definition update happens **automatically during Phase 3.5** of migration
- If a column already exists in the schema definition, it will be skipped
- The function handles missing schema files gracefully
- All changes are logged for debugging

## Troubleshooting

**Q: What if the schema file isn't found?**  
A: The function will log a warning and skip the schema update. The database columns will still be added.

**Q: What if I add a column that already exists?**  
A: The database will skip it (using `ADD COLUMN IF NOT EXISTS`), and the schema update will also skip it.

**Q: How do I verify the schema was updated?**  
A: Check the migration logs for messages like "Successfully updated schema definition file" or inspect `resources/schema_definition.json` directly.
