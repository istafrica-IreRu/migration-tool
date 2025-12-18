
import unittest
from unittest.mock import MagicMock, call
import sys
import os

# Add src to path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '../src')))

from validation import DataValidator, ValidationIssue

class TestDataValidator(unittest.TestCase):
    def setUp(self):
        self.mock_mssql = MagicMock()
        self.mock_pg = MagicMock()
        self.validator = DataValidator(self.mock_mssql, self.mock_pg)
        
    def test_compare_row_counts_match(self):
        # Setup
        metadata = {
            'dbo.Users': {
                'columns': [MagicMock(TABLE_SCHEMA='dbo', TABLE_NAME='Users')]
            }
        }
        
        # Mocks
        self.mock_mssql.cursor().fetchone.return_value = [100]
        self.mock_pg.cursor().fetchone.return_value = [100]
        
        # Execute
        results = self.validator.compare_row_counts(metadata)
        
        # Assert
        self.assertEqual(results['dbo.Users'], (100, 100))
        self.assertEqual(len(self.validator.issues), 0)

    def test_compare_row_counts_mismatch(self):
        # Setup
        metadata = {
            'dbo.Users': {
                'columns': [MagicMock(TABLE_SCHEMA='dbo', TABLE_NAME='Users')]
            }
        }
        
        # Mocks
        self.mock_mssql.cursor().fetchone.return_value = [100]
        self.mock_pg.cursor().fetchone.return_value = [90] # Target missing 10
        
        # Execute
        results = self.validator.compare_row_counts(metadata)
        
        # Assert
        self.assertEqual(results['dbo.Users'], (100, 90))
        self.assertEqual(len(self.validator.issues), 1)
        self.assertEqual(self.validator.issues[0].severity, 'error')
        self.assertIn("Row count mismatch", self.validator.issues[0].message)

    def test_check_target_null_values_detected(self):
        # Setup
        col_mock = MagicMock()
        col_mock.IS_NULLABLE = 'NO'
        col_mock.COLUMN_NAME = 'Username'
        
        metadata = {
            'dbo.Users': {
                'columns': [col_mock],
                'original_columns': {'Username': 'Username'}
            }
        }
        
        # Mock cursor for check
        cursor = self.mock_pg.cursor()
        # count query returns 5 nulls
        cursor.fetchone.return_value = [5]
        
        # Execute
        self.validator._check_target_null_values(cursor, 'public', 'Users', metadata['dbo.Users'])
        
        # Assert
        self.assertEqual(len(self.validator.issues), 1)
        self.assertIn("NULL values found", self.validator.issues[0].message)
        self.assertEqual(self.validator.issues[0].count, 5)

    def test_fetch_target_metadata(self):
        # Mocks
        cursor = self.mock_pg.cursor()
        
        # 1. Tables query result
        cursor.fetchall.side_effect = [
            [('NewTable',)],  # Tables
            [('ID', 'NO', 'int', None, None, None), ('Name', 'YES', 'varchar', 100, None, None)], # Columns
            [('PK_NewTable', 'ID')], # PKs
            [('FK_NewTable_Parent', 'ID', 'public', 'ParentTable', 'ID')] # FKs
        ]
        
        # Execute
        metadata = self.validator.fetch_target_metadata('public')
        
        # Assert
        self.assertIn('public.NewTable', metadata)
        table_data = metadata['public.NewTable']
        
        # Check columns
        self.assertEqual(len(table_data['columns']), 2)
        self.assertEqual(table_data['columns'][0].COLUMN_NAME, 'ID')
        self.assertEqual(table_data['columns'][1].IS_NULLABLE, 'YES')
        
        # Check constraints
        self.assertEqual(len(table_data['constraints']), 2)
        pk = next(c for c in table_data['constraints'] if c['type'] == 'PRIMARY KEY')
        self.assertEqual(pk['name'], 'PK_NewTable')
        self.assertEqual(pk['definition'], ['ID'])
        
        fk = next(c for c in table_data['constraints'] if c['type'] == 'FOREIGN KEY')
        self.assertEqual(fk['name'], 'FK_NewTable_Parent')
        self.assertEqual(fk['definition']['parent_table'], 'public.ParentTable')

    def test_compare_custom_counts(self):
        # Mocks
        # fetchone returns a row (tuple/list), so we must return [count], not count.
        self.mock_mssql.cursor().fetchone.side_effect = [[100], [100]] # Source counts 
        self.mock_pg.cursor().fetchone.side_effect = [[100], [50]]    # Target counts
        
        mappings = {
            'dbo.Source1': 'public.Target1',
            'dbo.Source2': 'public.Target2'
        }
        
        # Execute
        results = self.validator.compare_custom_counts(mappings)
        
        # Assert
        self.assertEqual(results['dbo.Source1 -> public.Target1'], (100, 100))
        self.assertEqual(results['dbo.Source2 -> public.Target2'], (100, 50))
        
        # Should have 1 error (mismatch) and 1 info (match)
        errors = [i for i in self.validator.issues if i.severity == 'error']
        info = [i for i in self.validator.issues if i.severity == 'info']
        
        self.assertEqual(len(errors), 1)
        self.assertIn("Row count mismatch (Normalization)", errors[0].message)
        
        self.assertEqual(len(info), 1)
        self.assertIn("Row count matched", info[0].message)

    def test_compare_internal_counts(self):
        # Mocks - ALL calls go to self.mock_pg
        # Sequence:
        # Comparison 1: Raw1 -> Norm1
        # 1. Source (Raw1) Count -> 100
        # 2. Target (Norm1) Count -> 100
        # Comparison 2: Raw1 -> Norm2 (One-to-Many Source)
        # 3. Source (Raw1) Count -> 100
        # 4. Target (Norm2) Count -> 90
        self.mock_pg.cursor().fetchone.side_effect = [[100], [100], [100], [90]]
        
        mappings = [
            ('public.RawTable1', 'public.NormTable1'),
            ('public.RawTable1', 'public.NormTable2')
        ]
        
        # Execute
        results = self.validator.compare_internal_counts(mappings)
        
        # Assert results
        self.assertEqual(results['public.RawTable1 -> public.NormTable1'], (100, 100))
        self.assertEqual(results['public.RawTable1 -> public.NormTable2'], (100, 90))
        
        # Assert Issues
        # Expect 1 Match (Info) and 1 Mismatch (Error)
        errors = [i for i in self.validator.issues if i.severity == 'error']
        infos = [i for i in self.validator.issues if i.severity == 'info']
        
        self.assertEqual(len(errors), 1)
        self.assertIn("Row count mismatch (Internal)", errors[0].message)
        self.assertIn("NormTable2", errors[0].message)
        
        
        self.assertEqual(len(infos), 1)
        self.assertIn("Row count matched", infos[0].message)
        self.assertEqual("public.NormTable1", infos[0].table)
        
        self.assertEqual(len(errors), 1)
        self.assertIn("Row count mismatch (Internal)", errors[0].message)
        self.assertEqual("public.NormTable2", errors[0].table)

if __name__ == '__main__':
    unittest.main()
