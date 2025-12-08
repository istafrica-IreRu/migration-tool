"""
Configuration loader for main.py
Loads environment variables from .env file
"""
import os
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

# MSSQL Connection Details (from environment variables)
MSSQL_SERVER = os.getenv('MSSQL_SERVER', 'IST-PF54N3DM')
MSSQL_DATABASE = os.getenv('MSSQL_DATABASE', 'wsdata')
MSSQL_USERNAME = os.getenv('MSSQL_USERNAME', '')  # Empty for Windows Authentication
MSSQL_PASSWORD = os.getenv('MSSQL_PASSWORD', '')  # Empty for Windows Authentication

# PostgreSQL Connection Details (from environment variables)
PG_HOST = os.getenv('PG_HOST', 'localhost')
PG_DATABASE = os.getenv('PG_DATABASE', 'wsdata_v4')
PG_USER = os.getenv('PG_USER', 'postgres')
PG_PASSWORD = os.getenv('PG_PASSWORD', 'postgres')
PG_PORT = os.getenv('PG_PORT', '5432')

# IMPORTANT: Add all schemas you want to migrate to this list
SCHEMAS_TO_MIGRATE = os.getenv('SCHEMAS_TO_MIGRATE', 'dbo,winSCHOOLPlus').split(',')
