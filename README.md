# WinSchool Migration Tool

A comprehensive database migration tool to migrate schemas, tables, data, constraints, indexes, and views from Microsoft SQL Server (MSSQL) to PostgreSQL, with a modern React frontend for easy management.

## Features

### 🚀 **Modern Web Interface**
- **React Frontend** with TypeScript and Tailwind CSS
- **Real-time Progress** tracking via WebSocket
- **Phase-based Migration** workflow:
  - **Phase 1**: Reading Database Structure (Raw Migration)
  - **Phase 2**: Modules Migration (Normalization)
- **Professional UI** with shadcn/ui components
- **Multi-select Module Migration** for Phase 2

### 🔄 **Migration Engine**
The core migration engine (`src/main.py`) performs:
- Fetches MSSQL metadata (schemas, tables, columns, constraints, indexes, views)
- Creates schemas in PostgreSQL (maps MSSQL `dbo` to PostgreSQL `public`)
- Creates tables with translated data types and default values
- Migrates data in dependency-safe order, cleaning NUL characters in text
- Adds new columns automatically after raw migration
- Adds primary keys, unique constraints, foreign keys, and indexes
- Translates and creates views when possible

### 📊 **API & WebSocket Server**
- **REST API** for migration control and status
- **WebSocket** for real-time progress updates
- **Flask-SocketIO** backend with CORS support
- Automated schema definition updates after migrations

### 🎯 **Normalization Modules**
Phase 2 supports multiple migration modules:
- **Users**: Normalized user tables
- **Enrollment**: Student enrollment data
- **Guardians**: Guardian/parent information
- **Academic**: Academic records and data

## Quick Start

### 1. **Configure Environment**
Copy `.env.example` to `.env` and update with your database credentials:
```bash
cp .env.example .env
```

Edit `.env` with your connection details:
```env
# MSSQL Configuration
MSSQL_SERVER=your_server
MSSQL_DATABASE=your_database
MSSQL_USERNAME=your_username
MSSQL_PASSWORD=your_password

# PostgreSQL Configuration
PG_HOST=localhost
PG_DATABASE=your_pg_database
PG_USER=your_pg_user
PG_PASSWORD=your_pg_password
PG_PORT=5432

# Migration Configuration
SCHEMAS_TO_MIGRATE=dbo,winSCHOOLPlus
```

### 2. **Install Dependencies**
```bash
# Python dependencies
pip install -r requirements.txt

# Frontend dependencies
cd frontend-lovable
npm install
cd ..
```

### 3. **Start the Backend**
```bash
python start_backend.py
# or directly: python src/api.py
```

### 4. **Start the Frontend**
```bash
cd frontend-lovable
npm run dev
```

### 5. **Access the Application**
- **Frontend**: http://localhost:5200
- **Backend API**: http://localhost:5000

## Prerequisites
- Python 3.9+
- Node.js 18+ (for frontend)
- Drivers and libraries:
  - ODBC Driver 17 for SQL Server (Windows): ensure it's installed
  - `pyodbc`, `psycopg2` (install via requirements)
- Access to source MSSQL and target PostgreSQL databases

## Configuration

### Environment Variables (.env)
The recommended way to configure the tool is via the `.env` file. See the Quick Start section above.

### Legacy Configuration (src/main.py)
Alternatively, you can edit connection settings at the top of `src/main.py`:
- MSSQL: `MSSQL_SERVER`, `MSSQL_DATABASE`, `MSSQL_USERNAME`, `MSSQL_PASSWORD`
- PostgreSQL: `PG_HOST`, `PG_DATABASE`, `PG_USER`, `PG_PASSWORD`, `PG_PORT`
- Schemas to include: `SCHEMAS_TO_MIGRATE = ['dbo', 'winSCHOOLPlus']` (adjust as needed)

## Command Line Usage (Advanced)

### Windows PowerShell
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

### Command Line Arguments
- `--translations-file` (required): Path to a JSON file mapping identifiers (e.g., German → English). Used for table and column name translation
- `--tables-file` (optional): Path to a text file with lines like `schema.TableName` to restrict migration to specific tables
- `--drop-existing` (flag): If provided, existing tables are dropped before creation

## Project Structure
```
.
├─ README.md
├─ requirements.txt
├─ .env.example                 # Environment configuration template
├─ .env                         # Your local configuration (not in git)
├─ start_backend.py             # Backend startup script
├─ pyproject.toml               # Python project configuration
├─ resources/
│  ├─ tables_to_migrate.txt     # Optional table filter
│  ├─ translations.json         # Column/table name translations
│  └─ schema_definition.json    # Auto-updated schema definitions
├─ src/
│  ├─ main.py                   # Core migration engine
│  ├─ api.py                    # Flask API & WebSocket server
│  ├─ config.py                 # Configuration loader
│  ├─ column_additions.py       # Automatic column additions
│  ├─ return_tables.py          # Table utilities
│  └─ tables_col.py             # Column utilities
├─ reference/                   # Normalization SQL scripts
│  ├─ V000__create_normalized_users_table.sql
│  ├─ V001__create_normalized_enrollment_tables.sql
│  ├─ V002__create_normalized_guardian_tables.sql
│  └─ V003__create_normalized_academic_tables.sql
├─ frontend-lovable/            # React frontend application
│  ├─ src/
│  ├─ package.json
│  └─ vite.config.ts
└─ docs/                        # Documentation
```

## Migration Workflow

### Phase 1: Reading Database Structure
1. Connects to MSSQL and PostgreSQL
2. Fetches all metadata (schemas, tables, columns, constraints, indexes, views)
3. Creates schemas in PostgreSQL
4. Creates table structures with translated column names
5. Migrates all data in dependency-safe order
6. Automatically adds new columns as needed
7. Adds constraints and indexes
8. Migrates views

### Phase 2: Modules Migration
1. Select one or more normalization modules
2. Executes SQL scripts to create normalized tables
3. Transforms and migrates data to normalized structure
4. Updates schema definitions automatically

## Key Behaviors
- Maps data types from MSSQL to PostgreSQL (e.g., `nvarchar(max)` → `TEXT`, `datetime` → `TIMESTAMP`)
- Resolves duplicate translated column names by appending numeric suffixes
- Handles identity columns using PostgreSQL `SERIAL`/`BIGSERIAL` and resets sequences
- Attempts to translate T-SQL view definitions to PostgreSQL SQL
- Cleans NUL characters from text data during migration

## Tips
- Ensure the ODBC connection string driver name in `get_mssql_connection()` matches your installed driver (e.g., `ODBC Driver 17 for SQL Server`)
- If some views cannot be translated, check `view_errors.json` for details
- For large datasets, migration logs progress every 1000 rows per table
- Use the web interface for the best experience with real-time progress tracking

## Safety and Credentials
- **Never commit `.env` file** to version control (already in `.gitignore`)
- Use `.env.example` as a template for team members
- Ensure proper database permissions before running migrations
- Test migrations on a non-production database first
