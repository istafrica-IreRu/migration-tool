# WinSchool Migration Tool

A comprehensive Python utility to migrate schemas, tables, data, constraints, indexes, and views from Microsoft SQL Server (MSSQL) to PostgreSQL, with a modern React frontend for easy management.

## Features

### 🚀 **Modern Web Interface**
- **React Frontend** with TypeScript and Tailwind CSS
- **Real-time Progress** tracking via WebSocket
- **Phase-based Migration** workflow (Raw Migration → Normalization)
- **Professional UI** with shadcn/ui components

### 🔄 **Migration Engine**
The core migration engine (`src/main.py`) performs:
- Fetches MSSQL metadata (schemas, tables, columns, constraints, indexes, views)
- Creates schemas in PostgreSQL (maps MSSQL `dbo` to PostgreSQL `public`)
- Creates tables with translated data types and default values
- Migrates data in dependency-safe order, cleaning NUL characters in text
- Adds primary keys, unique constraints, foreign keys, and indexes
- Translates and creates views when possible

### 📊 **API & WebSocket Server**
- **REST API** for migration control and status
- **WebSocket** for real-time progress updates
- **Flask-SocketIO** backend with CORS support

Arguments parsed by the script:
- `--translations-file` (required): Path to a JSON file mapping identifiers (e.g., German → English). Used for table and column name translation
- `--tables-file` (optional): Path to a text file with lines like `schema.TableName` to restrict migration to specific tables
- `--drop-existing` (flag): If provided, existing tables are dropped before creation

Key behaviors:
- Maps data types from MSSQL to PostgreSQL (e.g., `nvarchar(max)` → `TEXT`, `datetime` → `TIMESTAMP`)
- Resolves duplicate translated column names by appending numeric suffixes
- Handles identity columns using PostgreSQL `SERIAL`/`BIGSERIAL` and resets sequences
- Attempts to translate T-SQL view definitions to PostgreSQL SQL

## Quick Start

### 1. **Start the Backend**
```bash
python start_backend.py
# or directly: python src/api.py
```

### 2. **Start the Frontend**
```bash
cd frontend-lovable
npm install
npm run dev
```

### 3. **Access the Application**
- **Frontend**: http://localhost:8080
- **Backend API**: http://localhost:5000

## Prerequisites
- Python 3.9+
- Node.js 18+ (for frontend)
- Drivers and libraries:
  - ODBC Driver 17 for SQL Server (Windows): ensure it's installed
  - `pyodbc`, `psycopg2` (install via requirements)
- Access to source MSSQL and target PostgreSQL

## Configuration
Edit connection settings at the top of `src/main.py`:
- MSSQL: `MSSQL_SERVER`, `MSSQL_DATABASE`, `MSSQL_USERNAME`, `MSSQL_PASSWORD`
- PostgreSQL: `PG_HOST`, `PG_DATABASE`, `PG_USER`, `PG_PASSWORD`, `PG_PORT`
- Schemas to include: `SCHEMAS_TO_MIGRATE = ['dbo', 'winSCHOOLPlus']` (adjust as needed)

## Quick start (Windows PowerShell)
```powershell
# (optional) create and activate a virtual environment
python -m venv .venv
.\.venv\Scripts\Activate.ps1

# install dependencies
pip install -r requirements.txt

# run a full migration for configured schemas
python .\src\main.py --translations-file .\resources\translations.json

# run a restricted migration for specific tables
python .\src\main.py `
  --translations-file .\resources\translations.json `
  --tables-file .\resources\tables_to_migrate.txt

# drop and recreate tables before migrating
python .\src\main.py --translations-file .\resources\translations.json --drop-existing
```

## Project layout
```
.
├─ README.md
├─ requirements.txt
├─ resources/
│  ├─ tables_to_migrate.txt
│  └─ translations.json
└─ src/
   ├─ main.py
   ├─ return_tables.py
   └─ tables_col.py
```

## Tips
- Ensure the ODBC connection string driver name in `get_mssql_connection()` matches your installed driver (e.g., `ODBC Driver 17 for SQL Server`)
- If some views cannot be translated, check `view_errors.json` for details
- For large datasets, migration logs progress every 10k rows per table

## Safety and credentials
- Do not commit real database credentials to version control
- Use environment variables or a config file in production environments
