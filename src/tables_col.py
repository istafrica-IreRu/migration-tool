import json

# Choose your database type: 'postgres', 'mysql', or 'sqlite'
DB_TYPE = "postgres"  # Change this to 'mysql' or 'sqlite' as needed

# Configuration for Postgres/MySQL
DB_CONFIG = {
    "host": "localhost",
    "user": "postgres",
    "password": "123",
    "database": "wsdata"
}

# SQLite file path (only used if DB_TYPE == 'sqlite')
# SQLITE_DB_PATH = "example.db"

# List of tables to inspect
TABLES_TO_CHECK = ["InventoryBooks", "BookLoans", "BookReservations", "Classes", "ClassBooks", "Courses", "CourseBooks", "Users", "Teachers", "BookTransactions", "Students"]  # Add your table names here


def get_table_columns(cursor, table_name, db_type):
    columns = []
    if db_type == "postgres":
        cursor.execute("""
            SELECT column_name, data_type 
            FROM information_schema.columns 
            WHERE table_name = %s
        """, (table_name,))
        columns = cursor.fetchall()

    elif db_type == "mysql":
        cursor.execute("""
            SELECT column_name, data_type 
            FROM information_schema.columns 
            WHERE table_name = %s AND table_schema = DATABASE()
        """, (table_name,))
        columns = cursor.fetchall()

    elif db_type == "sqlite":
        cursor.execute(f"PRAGMA table_info({table_name})")
        # Returns (cid, name, type, notnull, dflt_value, pk)
        columns = [(row[1], row[2]) for row in cursor.fetchall()]

    return columns


def main():
    connection = None
    cursor = None

    try:
        if DB_TYPE == "postgres":
            import psycopg2
            connection = psycopg2.connect(**DB_CONFIG)
            cursor = connection.cursor()

        elif DB_TYPE == "mysql":
            import mysql.connector
            connection = mysql.connector.connect(**DB_CONFIG)
            cursor = connection.cursor()

        elif DB_TYPE == "sqlite":
            import sqlite3
            connection = sqlite3.connect(SQLITE_DB_PATH)
            cursor = connection.cursor()

        else:
            raise ValueError("Unsupported DB_TYPE")

        result = {}

        for table in TABLES_TO_CHECK:
            print(f"Fetching schema for table: {table}")
            columns = get_table_columns(cursor, table, DB_TYPE)
            result[table] = {col[0]: col[1] for col in columns}

        # Print result in JSON format
        print("\nSchema Result:")
        print(json.dumps(result, indent=4))

    except Exception as e:
        print(f"[ERROR] {e}")
    finally:
        if cursor:
            cursor.close()
        if connection:
            connection.close()


if __name__ == "__main__":
    main()