"""
Test script to verify that schema_definition.json is updated correctly
when new columns are added.
"""
import json
import os
import sys

# Add src directory to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'src'))

from column_additions import update_schema_definition


def test_schema_update():
    """Test the schema definition update function."""
    
    # Create a test schema update map
    test_columns = {
        'ApplicantTable': [
            ('UserID', 'INTEGER', True, None, 'User ID reference'),
        ],
        'TestTable': [
            ('Status', 'SMALLINT', False, '1', 'Status of the record'),
            ('IsDraft', 'SMALLINT', False, '0', 'Draft indicator'),
        ]
    }
    
    print("Testing schema definition update...")
    print(f"Test columns: {test_columns}")
    
    # Backup the original schema file
    schema_file_path = os.path.join(os.path.dirname(__file__), 'resources', 'schema_definition.json')
    backup_path = schema_file_path + '.backup'
    
    if os.path.exists(schema_file_path):
        with open(schema_file_path, 'r', encoding='utf-8') as f:
            original_content = f.read()
        with open(backup_path, 'w', encoding='utf-8') as f:
            f.write(original_content)
        print(f"✓ Backed up original schema to {backup_path}")
    
    # Call the update function
    update_schema_definition(test_columns)
    
    # Verify the update
    if os.path.exists(schema_file_path):
        with open(schema_file_path, 'r', encoding='utf-8') as f:
            updated_schema = json.load(f)
        
        print("\n✓ Schema definition file updated successfully!")
        print("\nUpdated schema content:")
        print(json.dumps(updated_schema, indent=2))
        
        # Check if ApplicantTable has UserID column
        if 'ApplicantTable' in updated_schema:
            columns = [col['name'] for col in updated_schema['ApplicantTable'].get('new_columns', [])]
            if 'UserID' in columns:
                print("\n✓ ApplicantTable.UserID column found in schema!")
            else:
                print("\n✗ ApplicantTable.UserID column NOT found in schema!")
        
        # Restore the original schema
        if os.path.exists(backup_path):
            with open(backup_path, 'r', encoding='utf-8') as f:
                original_content = f.read()
            with open(schema_file_path, 'w', encoding='utf-8') as f:
                f.write(original_content)
            os.remove(backup_path)
            print("\n✓ Restored original schema from backup")
    else:
        print("\n✗ Schema definition file not found!")


if __name__ == "__main__":
    test_schema_update()
