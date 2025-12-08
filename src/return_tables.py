import pyodbc
import json

# --- CONFIGURATION ---
server = 'a_wanderer'  # e.g., 'localhost\\SQLEXPRESS'
database = 'wsdata'
username = 'ws_admin'
password = '123'

# Tables to inspect - leave empty to query all tables
target_tables = []

# --- CONNECTION STRING ---
conn_str = (
    f'DRIVER={{ODBC Driver 17 for SQL Server}};'
    f'SERVER={server};DATABASE={database};UID={username};PWD={password}'
)

# --- HELPER FUNCTIONS ---
def get_all_tables(cursor):
    """Get all user tables from all schemas in the database"""
    cursor.execute("""
        SELECT TABLE_SCHEMA, TABLE_NAME
        FROM INFORMATION_SCHEMA.TABLES
        WHERE TABLE_TYPE = 'BASE TABLE'
        ORDER BY TABLE_SCHEMA, TABLE_NAME
    """)
    return [(row.TABLE_SCHEMA, row.TABLE_NAME) for row in cursor.fetchall()]

def get_table_columns(cursor, schema_name, table_name):
    """Get columns for a specific table in a specific schema"""
    cursor.execute("""
        SELECT COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_SCHEMA = ? AND TABLE_NAME = ?
        ORDER BY ORDINAL_POSITION
    """, schema_name, table_name)
    rows = cursor.fetchall()
    columns = []
    for row in rows:
        col_name = row.COLUMN_NAME
        col_type = row.DATA_TYPE
        col_len = f"({row.CHARACTER_MAXIMUM_LENGTH})" if row.CHARACTER_MAXIMUM_LENGTH else ""
        columns.append({
            "name": col_name,
            "type": col_type + col_len,
            "translation": ""
        })
    return columns

def list_table_columns_for_table(cursor, schema_name, table_name):
    """List columns for a specific table in a specific schema"""
    print(f"\n📘 Table: {schema_name}.{table_name}")
    columns = get_table_columns(cursor, schema_name, table_name)
    if not columns:
        print("   ⚠️ Table not found or no columns.")
        return columns
    for col in columns:
        print(f"   - {col['name']}: {col['type']}")
    return columns

def write_translations_to_json(tables_data):
    """Write tables and columns data to translations.json file"""
    try:
        # Read existing translations if file exists
        existing_translations = {}
        try:
            with open('translations.json', 'r', encoding='utf-8') as f:
                existing_translations = json.load(f)
        except FileNotFoundError:
            print("📄 Creating new translations.json file")
        except json.JSONDecodeError:
            print("⚠️ Existing translations.json is invalid, creating new file")
            existing_translations = {}
        
        # Add table names and column names to translations
        new_entries = 0
        for table_key, table_info in tables_data.items():
            # Add table name if not already present
            table_name = table_info['table_name']
            if table_name not in existing_translations:
                existing_translations[table_name] = ""
                new_entries += 1
            
            # Add column names if not already present
            for column in table_info['columns']:
                column_name = column['name']
                if column_name not in existing_translations:
                    existing_translations[column_name] = ""
                    new_entries += 1
        
        # Write back to file
        with open('translations.json', 'w', encoding='utf-8') as f:
            json.dump(existing_translations, f, indent=4, ensure_ascii=False)
        
        print(f"\n💾 Successfully updated translations.json")
        print(f"📝 Added {new_entries} new entries (tables and columns)")
        print(f"📊 Total entries in file: {len(existing_translations)}")
        
    except Exception as e:
        print(f"❌ Error writing to translations.json: {e}")

# --- MAIN FUNCTION ---
def list_table_columns():
    try:
        with pyodbc.connect(conn_str) as conn:
            cursor = conn.cursor()
            
            # Determine which tables to process
            if not target_tables:
                print("🔍 No target tables specified. Querying all database tables from all schemas...")
                tables_to_process = get_all_tables(cursor)
                print(f"📊 Found {len(tables_to_process)} tables to process")
                
                # Group tables by schema for better organization
                schemas = {}
                for schema, table in tables_to_process:
                    if schema not in schemas:
                        schemas[schema] = []
                    schemas[schema].append(table)
                
                print(f"📁 Found {len(schemas)} schemas: {', '.join(schemas.keys())}")
            else:
                # For specified tables, assume they're in dbo schema if no schema specified
                tables_to_process = []
                for table in target_tables:
                    if '.' in table:
                        schema, table_name = table.split('.', 1)
                        tables_to_process.append((schema, table_name))
                    else:
                        tables_to_process.append(('dbo', table))
                print(f"🎯 Processing {len(tables_to_process)} specified table(s)")
            
            # Process each table and collect data
            processed_count = 0
            tables_data = {}
            
            for schema, table in tables_to_process:
                columns = list_table_columns_for_table(cursor, schema, table)
                if columns:
                    table_key = f"{schema}.{table}"
                    tables_data[table_key] = {
                        "table_name": table,
                        "schema": schema,
                        "translation": "",
                        "columns": columns
                    }
                    processed_count += 1
                
            print(f"\n✅ Processing complete! Total tables processed: {processed_count}")
            
            # Write to translations.json
            write_translations_to_json(tables_data)
            
            return processed_count
                
    except pyodbc.Error as e:
        print("❌ Database error:", e)
        return 0

# --- EXECUTE ---
if __name__ == "__main__":
    tables_processed = list_table_columns()
    print(f"📈 Summary: {tables_processed} tables processed successfully")
