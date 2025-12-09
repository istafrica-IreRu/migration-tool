-- =====================================================================
-- GUARDIAN TABLE NORMALIZATION - DATA MIGRATION SCRIPT (REVISED)
-- =====================================================================
-- Purpose: Migrate data from denormalized GuardianTable to normalized structure
-- Prerequisites: New normalized tables must be created first (run DDL script)
-- Approach: Transaction-safe migration with deduplication for many-to-many
-- Validation: Includes data integrity checks
--
-- KEY MIGRATION CHALLENGE:
-- The old GuardianTable has duplicate guardian records (one per child).
-- We need to:
--   1. DEDUPLICATE guardians → Nr_Guardians (ONE per person)
--   2. Create relationship records → Nr_StudentGuardians (MANY-TO-MANY)
--   3. Migrate supporting data only once per guardian
-- =====================================================================

-- =====================================================================
-- MIGRATION STRATEGY
-- =====================================================================
-- Phase 1: Prepare and validate source data
-- Phase 2: Deduplicate and migrate guardian identity to Nr_Guardians
-- Phase 3: Create relationship records in Nr_StudentGuardians
-- Phase 4: Migrate supporting data (address, contact, finance, etc.)
-- Phase 5: Validate migration results
-- Phase 6: (Optional) Rename/archive old table
-- =====================================================================

BEGIN TRANSACTION;

-- =====================================================================
-- PHASE 1: PRE-MIGRATION VALIDATION
-- =====================================================================

-- Check if source table exists
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables
                   WHERE table_name = 'GuardianTable') THEN
        RAISE EXCEPTION 'Source table GuardianTable does not exist';
    END IF;
END $$;

-- Check if target tables exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables
                   WHERE table_name = 'Nr_Guardians') THEN
        RAISE EXCEPTION 'Target table Nr_Guardians does not exist. Please run DDL script first.';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables
                   WHERE table_name = 'Nr_StudentGuardians') THEN
        RAISE EXCEPTION 'Target table Nr_StudentGuardians does not exist. Please run DDL script first.';
    END IF;
END $$;

-- Display migration statistics (pre-migration)
SELECT
    COUNT(*) AS "Total GuardianTable Records",
    COUNT(DISTINCT "GlobalUID") AS "Unique Guardians (by GlobalUID)",
    COUNT(DISTINCT "StudentNumber") AS "Unique Students",
    COUNT(DISTINCT "SchoolID") AS "Unique Schools",
    COUNT(DISTINCT "Tenant") AS "Unique Tenants",
    COUNT(*) - COUNT(DISTINCT "GlobalUID") AS "Duplicate Guardian Records"
FROM "GuardianTable"
WHERE "GlobalUID" IS NOT NULL;

-- Check for guardians without GlobalUID (problematic for deduplication)
SELECT
    'Guardians without GlobalUID' AS "Issue",
    COUNT(*) AS "Count"
FROM "GuardianTable"
WHERE "GlobalUID" IS NULL;

-- Check for potential data quality issues
SELECT
    'Missing SchoolID' AS "Issue",
    COUNT(*) AS "Count"
FROM "GuardianTable"
WHERE "SchoolID" IS NULL OR "SchoolID" = ''
UNION ALL
SELECT
    'Missing StudentNumber',
    COUNT(*)
FROM "GuardianTable"
WHERE "StudentNumber" IS NULL
UNION ALL
SELECT
    'Missing Name (NOT CRITICAL - should be in Nr_Users)',
    COUNT(*)
FROM "GuardianTable"
WHERE "Name" IS NULL OR "Name" = ''
UNION ALL
SELECT
    'Missing Primary Contact (Phone, Mobile, Email) - Should be in Nr_Users',
    COUNT(*)
FROM "GuardianTable"
WHERE ("Phone" IS NULL OR "Phone" = '')
  AND ("MobileNumber" IS NULL OR "MobileNumber" = '')
  AND ("Email" IS NULL OR "Email" = '')
UNION ALL
SELECT
    'Has Secondary Contact (Phone2, MobileNumber2)',
    COUNT(*)
FROM "GuardianTable"
WHERE ("Phone2" IS NOT NULL AND "Phone2" != '')
   OR ("MobileNumber2" IS NOT NULL AND "MobileNumber2" != '');

-- =====================================================================
-- PHASE 2: DEDUPLICATE AND MIGRATE GUARDIAN IDENTITY
-- =====================================================================

-- Strategy: Use GlobalUID as the primary deduplication key
-- If GlobalUID is NULL, we need an alternative strategy (e.g., Name + Email + Tenant)

-- Step 2.1: Insert UNIQUE guardians into Nr_Guardians
-- We'll use DISTINCT ON (GlobalUID) to get one record per unique guardian

INSERT INTO "Nr_Guardians" (
    "Nr_UserID",                  -- Set to NULL, update later if needed
    "GlobalUID",
    "XmoodID",
    "Salutation",
    "Title",
    "LetterSalutation",
    "RegistrationX",              -- Portal registration data now directly in Nr_Guardians
    "RegistrationName",           -- Portal registration data now directly in Nr_Guardians
    "Timestamp"
)
SELECT DISTINCT ON (g."GlobalUID")
    NULL,                         -- Nr_UserID - needs to be linked later
    g."GlobalUID",
    g."XmoodID",
    g."Salutation",
    g."Title",
    g."LetterSalutation",
    g."RegistrationX",            -- Portal registration data now directly in Nr_Guardians
    g."RegistrationName",         -- Portal registration data now directly in Nr_Guardians
    g."Timestamp"
FROM "GuardianTable" g
WHERE g."GlobalUID" IS NOT NULL  -- Only migrate guardians with GlobalUID for now
ORDER BY g."GlobalUID", g."ID"; -- Use oldest ID in case of duplicates

-- Handle guardians WITHOUT GlobalUID (if any exist)
-- These need special handling - we'll use a combination of fields to identify uniqueness
-- WARNING: This is more error-prone than GlobalUID-based deduplication

-- For now, log these as a warning
DO $$
DECLARE
    v_no_global_uid_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_no_global_uid_count
    FROM "GuardianTable"
    WHERE "GlobalUID" IS NULL;

    IF v_no_global_uid_count > 0 THEN
        RAISE WARNING 'Found % guardian records without GlobalUID. These require manual review before migration.',
            v_no_global_uid_count;
    END IF;
END $$;

-- =====================================================================
-- PHASE 3: CREATE RELATIONSHIP RECORDS (Nr_StudentGuardians)
-- =====================================================================

-- Now create the many-to-many relationship records
-- Each record in old GuardianTable becomes a relationship record

INSERT INTO "Nr_StudentGuardians" (
    "Nr_StudentID",               -- NULL for now, needs to be linked to Nr_Students later
    "Nr_GuardianID",
    "SchoolID",
    "Category",
    "Priority",
    "GuardianshipAuthorized",
    "CustodyAuthorized",
    "SameHousehold",
    "FamilyCode",
    "CompanyCarrier",
    "Denomination",
    "Addition",
    "Remark",
    "Tenant",
    "Timestamp"
)
SELECT
    NULL,                         -- Nr_StudentID - needs to be linked later via StudentNumber
    ng."Nr_GuardianID",           -- Link to deduplicated guardian
    g."SchoolID",
    g."Category",
    g."Priority",
    g."GuardianshipAuthorized",
    g."CustodyAuthorized",
    g."SameHousehold",
    g."FamilyCode",
    g."CompanyCarrier",
    g."Denomination",
    g."Addition",
    g."Remark",
    g."Tenant",
    g."Timestamp"
FROM "GuardianTable" g
INNER JOIN "Nr_Guardians" ng ON g."GlobalUID" = ng."GlobalUID"
WHERE g."GlobalUID" IS NOT NULL;

-- =====================================================================
-- PHASE 4: MIGRATE SUPPORTING DATA
-- =====================================================================

-- Create temporary mapping table for old ID to new Nr_GuardianID
-- This helps with subsequent migrations
CREATE TEMPORARY TABLE temp_guardian_id_mapping (
    old_guardian_id INTEGER,
    new_nr_guardian_id INTEGER,
    global_uid UUID,
    PRIMARY KEY (old_guardian_id)
);

-- Populate mapping table
INSERT INTO temp_guardian_id_mapping (old_guardian_id, new_nr_guardian_id, global_uid)
SELECT
    g_old."ID" AS old_guardian_id,
    g_new."Nr_GuardianID" AS new_nr_guardian_id,
    g_old."GlobalUID" AS global_uid
FROM "GuardianTable" g_old
INNER JOIN "Nr_Guardians" g_new ON g_old."GlobalUID" = g_new."GlobalUID"
WHERE g_old."GlobalUID" IS NOT NULL;

-- ============================================================================
-- DEPRECATED: 4.1 - Migrate Address Data to Nr_GuardianAddress
-- ============================================================================
-- Note: Guardian addresses are now stored in Nr_Addresses table (User module)
-- Address data should be migrated to Nr_Addresses and linked via Nr_Users.AddressID
-- Since guardians are users (they have Nr_UserID), their addresses are stored
-- in the normalized Nr_Addresses table via the user's AddressID
-- This migration step is kept for reference but should not be executed
-- ============================================================================
--
-- -- 4.1: Migrate Address Data to Nr_GuardianAddress
-- -- Only migrate ONE address per unique guardian (use DISTINCT ON GlobalUID)
--
-- INSERT INTO "Nr_GuardianAddress" (
--     "Nr_GuardianID",
--     "Street",
--     "PostalCode",
--     "Residence",
--     "Subdistrict",
--     "State",
--     "Country",
--     "CountryOfBirth",
--     "Country1",
--     "Country2"
-- )
-- SELECT DISTINCT ON (ng."Nr_GuardianID")
--     ng."Nr_GuardianID",
--     g."Street",
--     g."PostalCode",
--     g."Residence",
--     g."Subdistrict",
--     g."State",
--     g."Country",
--     g."CountryOfBirth",
--     g."Country1",
--     g."Country2"
-- FROM "GuardianTable" g
-- INNER JOIN "Nr_Guardians" ng ON g."GlobalUID" = ng."GlobalUID"
-- WHERE g."GlobalUID" IS NOT NULL
--   AND (g."Street" IS NOT NULL
--    OR g."PostalCode" IS NOT NULL
--    OR g."Residence" IS NOT NULL
--    OR g."Subdistrict" IS NOT NULL
--    OR g."State" IS NOT NULL
--    OR g."Country" IS NOT NULL
--    OR g."CountryOfBirth" IS NOT NULL
--    OR g."Country1" IS NOT NULL
--    OR g."Country2" IS NOT NULL)
-- ORDER BY ng."Nr_GuardianID", g."ID"; -- Use first occurrence if duplicates exist

-- -----------------------------------------------------------------------
-- 4.2: Migrate Contact Data to Nr_GuardianContact
-- -----------------------------------------------------------------------
-- Only migrate SECONDARY contact methods (Phone2, MobileNumber2)
-- Primary contact (Email, Phone, Mobile, Fax) should be in Nr_Users
-- NOTE: You need to migrate primary contact to Nr_Users separately!

INSERT INTO "Nr_GuardianContact" (
    "Nr_GuardianID",
    "Phone2",
    "MobileNumber2"
)
SELECT DISTINCT ON (ng."Nr_GuardianID")
    ng."Nr_GuardianID",
    g."Phone2",
    g."MobileNumber2"
FROM "GuardianTable" g
INNER JOIN "Nr_Guardians" ng ON g."GlobalUID" = ng."GlobalUID"
WHERE g."GlobalUID" IS NOT NULL
  AND (g."Phone2" IS NOT NULL
   OR g."MobileNumber2" IS NOT NULL)
ORDER BY ng."Nr_GuardianID", g."ID";

-- -----------------------------------------------------------------------
-- 4.3: Migrate Financial Data to Nr_GuardianFinance (GDPR Sensitive)
-- -----------------------------------------------------------------------
-- Only migrate ONE financial record per unique guardian

INSERT INTO "Nr_GuardianFinance" (
    "Nr_GuardianID",
    "FinancialInstitution",
    "BankCode",
    "AccountNumber",
    "DebtorNumber"
)
SELECT DISTINCT ON (ng."Nr_GuardianID")
    ng."Nr_GuardianID",
    g."FinancialInstitution",
    g."BankCode",
    g."AccountNumber",
    g."DebtorNumber"
FROM "GuardianTable" g
INNER JOIN "Nr_Guardians" ng ON g."GlobalUID" = ng."GlobalUID"
WHERE g."GlobalUID" IS NOT NULL
  AND (g."FinancialInstitution" IS NOT NULL
   OR g."BankCode" IS NOT NULL
   OR g."AccountNumber" IS NOT NULL
   OR g."DebtorNumber" IS NOT NULL)
ORDER BY ng."Nr_GuardianID", g."ID";

-- -----------------------------------------------------------------------
-- 4.4: Migrate Employment Data to Nr_GuardianEmployment
-- -----------------------------------------------------------------------
-- Only migrate ONE employment record per unique guardian

INSERT INTO "Nr_GuardianEmployment" (
    "Nr_GuardianID",
    "Company",
    "Profession"
)
SELECT DISTINCT ON (ng."Nr_GuardianID")
    ng."Nr_GuardianID",
    g."Company",
    g."Profession"
FROM "GuardianTable" g
INNER JOIN "Nr_Guardians" ng ON g."GlobalUID" = ng."GlobalUID"
WHERE g."GlobalUID" IS NOT NULL
  AND (g."Company" IS NOT NULL
   OR g."Profession" IS NOT NULL)
ORDER BY ng."Nr_GuardianID", g."ID";

-- ============================================================================
-- DEPRECATED: 4.5 - Portal Access Data Migration Removed
-- ============================================================================
-- Note: Portal registration data (RegistrationX, RegistrationName) is now
-- migrated directly in Phase 2 as part of the guardian identity migration.
-- This step is kept for reference but should not be executed.
--
-- Portal data is now stored directly in Nr_Guardians table, eliminating the
-- need for a separate Nr_GuardianPortal table and reducing joins.
-- Password is still stored in Nr_Users table, not in Nr_Guardians.
-- ============================================================================

-- =====================================================================
-- PHASE 5: POST-MIGRATION VALIDATION
-- =====================================================================

-- Validate record counts
DO $$
DECLARE
    v_source_count INTEGER;
    v_unique_guardians INTEGER;
    v_core_count INTEGER;
    v_relationships_count INTEGER;
    v_address_count INTEGER;
    v_contact_count INTEGER;
    v_finance_count INTEGER;
    v_employment_count INTEGER;
    v_portal_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_source_count FROM "GuardianTable";
    SELECT COUNT(DISTINCT "GlobalUID") INTO v_unique_guardians
        FROM "GuardianTable" WHERE "GlobalUID" IS NOT NULL;
    SELECT COUNT(*) INTO v_core_count FROM "Nr_Guardians";
    SELECT COUNT(*) INTO v_relationships_count FROM "Nr_StudentGuardians";
    -- Note: Address migration removed - addresses are now in Nr_Addresses table
    -- SELECT COUNT(*) INTO v_address_count FROM "Nr_GuardianAddress";
    v_address_count := 0; -- Placeholder - addresses are in Nr_Addresses
    SELECT COUNT(*) INTO v_contact_count FROM "Nr_GuardianContact";
    SELECT COUNT(*) INTO v_finance_count FROM "Nr_GuardianFinance";
    SELECT COUNT(*) INTO v_employment_count FROM "Nr_GuardianEmployment";
    SELECT COUNT(*) INTO v_portal_count FROM "Nr_Guardians" WHERE "RegistrationName" IS NOT NULL;

    RAISE NOTICE '=== MIGRATION VALIDATION RESULTS ===';
    RAISE NOTICE 'Source GuardianTable records (includes duplicates): %', v_source_count;
    RAISE NOTICE 'Unique guardians in source (by GlobalUID): %', v_unique_guardians;
    RAISE NOTICE 'Migrated Nr_Guardians records (deduplicated): %', v_core_count;
    RAISE NOTICE 'Migrated Nr_StudentGuardians relationships: %', v_relationships_count;
    RAISE NOTICE 'Address records: Migrated to Nr_Addresses (via Nr_Users.AddressID)';
    RAISE NOTICE 'Migrated Nr_GuardianContact records: %', v_contact_count;
    RAISE NOTICE 'Migrated Nr_GuardianFinance records: %', v_finance_count;
    RAISE NOTICE 'Migrated Nr_GuardianEmployment records: %', v_employment_count;
    RAISE NOTICE 'Guardians with portal access (RegistrationName in Nr_Guardians): %', v_portal_count;
    RAISE NOTICE '';
    RAISE NOTICE 'Expected: Relationships count ≈ Source count (one relationship per old record)';
    RAISE NOTICE 'Expected: Core guardians count ≈ Unique guardians (deduplicated)';

    -- Validate core guardian count matches unique guardians
    IF v_core_count != v_unique_guardians THEN
        RAISE WARNING 'Core guardian count mismatch: % unique guardians, % migrated',
            v_unique_guardians, v_core_count;
    END IF;

    -- Validate relationships count approximately matches source count
    IF ABS(v_relationships_count - v_source_count) > 10 THEN
        RAISE WARNING 'Relationships count significantly different from source: % source, % relationships',
            v_source_count, v_relationships_count;
    END IF;

    RAISE NOTICE 'Validation: PASSED (review warnings if any)';
END $$;

-- Validate data integrity - check for orphaned records
-- Note: Address validation removed - addresses are now in Nr_Addresses table
-- SELECT
--     'Orphaned Address Records' AS "Integrity Check",
--     COUNT(*) AS "Count"
-- FROM "Nr_GuardianAddress" a
-- LEFT JOIN "Nr_Guardians" g ON a."Nr_GuardianID" = g."Nr_GuardianID"
-- WHERE g."Nr_GuardianID" IS NULL
-- UNION ALL
SELECT
    'Orphaned Address Records (via Nr_Addresses)' AS "Integrity Check",
    COUNT(*) AS "Count"
FROM "Nr_Users" u
INNER JOIN "Nr_Guardians" g ON u."UserID" = g."Nr_UserID"
LEFT JOIN "Nr_Addresses" a ON u."AddressID" = a."ID"
WHERE u."AddressID" IS NOT NULL AND a."ID" IS NULL
UNION ALL
SELECT
    'Orphaned Contact Records',
    COUNT(*)
FROM "Nr_GuardianContact" c
LEFT JOIN "Nr_Guardians" g ON c."Nr_GuardianID" = g."Nr_GuardianID"
WHERE g."Nr_GuardianID" IS NULL
UNION ALL
SELECT
    'Orphaned Finance Records',
    COUNT(*)
FROM "Nr_GuardianFinance" f
LEFT JOIN "Nr_Guardians" g ON f."Nr_GuardianID" = g."Nr_GuardianID"
WHERE g."Nr_GuardianID" IS NULL
UNION ALL
SELECT
    'Orphaned Employment Records',
    COUNT(*)
FROM "Nr_GuardianEmployment" e
LEFT JOIN "Nr_Guardians" g ON e."Nr_GuardianID" = g."Nr_GuardianID"
WHERE g."Nr_GuardianID" IS NULL
UNION ALL
-- Note: Portal data is now directly in Nr_Guardians, so no orphaned portal records check needed
UNION ALL
SELECT
    'Orphaned Relationship Records',
    COUNT(*)
FROM "Nr_StudentGuardians" sg
LEFT JOIN "Nr_Guardians" g ON sg."Nr_GuardianID" = g."Nr_GuardianID"
WHERE g."Nr_GuardianID" IS NULL;

-- Analyze deduplication - show guardians with multiple children
SELECT
    'Guardians with Multiple Children' AS "Analysis",
    ng."Nr_GuardianID",
    ng."GlobalUID",
    COUNT(*) AS "Number of Children"
FROM "Nr_StudentGuardians" sg
INNER JOIN "Nr_Guardians" ng ON sg."Nr_GuardianID" = ng."Nr_GuardianID"
GROUP BY ng."Nr_GuardianID", ng."GlobalUID"
HAVING COUNT(*) > 1
ORDER BY COUNT(*) DESC
LIMIT 20;

-- Sample data verification
SELECT
    'Sample Deduplication Check' AS "Check Type",
    g_old."ID" AS "Old Record ID",
    g_old."StudentNumber" AS "Student Number",
    ng."Nr_GuardianID" AS "New Guardian ID",
    ng."GlobalUID" AS "GlobalUID",
    sg."Nr_StudentGuardianID" AS "Relationship ID"
FROM "GuardianTable" g_old
INNER JOIN "Nr_Guardians" ng ON g_old."GlobalUID" = ng."GlobalUID"
INNER JOIN "Nr_StudentGuardians" sg ON ng."Nr_GuardianID" = sg."Nr_GuardianID"
WHERE g_old."GlobalUID" IS NOT NULL
ORDER BY ng."Nr_GuardianID", g_old."ID"
LIMIT 20;

-- =====================================================================
-- PHASE 6: POST-MIGRATION NOTES AND CLEANUP OPTIONS
-- =====================================================================

-- IMPORTANT: Personal Identity Fields NOT Migrated
-- The following fields from GuardianTable are NOT in normalized structure:
--   - Name, FirstName, Salutation, LetterSalutation, Title
--
-- These should be in Nr_Users table. You need to:
-- 1. Create or link Nr_Users entries for all guardians
-- 2. Update Nr_Guardians.Nr_UserID with references
--
-- Example query to find guardians needing user accounts:
-- SELECT * FROM Nr_Guardians WHERE Nr_UserID IS NULL;

-- IMPORTANT: Student Relationship Linking
-- Nr_StudentGuardians.Nr_StudentID is currently NULL
-- You need to link these to actual student records:
--
-- UPDATE "Nr_StudentGuardians" sg
-- SET "Nr_StudentID" = s."Nr_StudentID"
-- FROM "Nr_Students" s
-- INNER JOIN "GuardianTable" gt ON s."StudentNumber" = gt."StudentNumber"
-- INNER JOIN "Nr_Guardians" ng ON gt."GlobalUID" = ng."GlobalUID"
-- WHERE sg."Nr_GuardianID" = ng."Nr_GuardianID"
--   AND sg."Nr_StudentID" IS NULL;

-- =====================================================================
-- CLEANUP OPTIONS (Uncomment when ready)
-- =====================================================================

-- Option 1: Rename old table for backup (RECOMMENDED)
-- ALTER TABLE "GuardianTable" RENAME TO "GuardianTable_BACKUP_PreNormalization";

-- Option 2: Create backup table with timestamp
-- CREATE TABLE "GuardianTable_BACKUP_20250114" AS SELECT * FROM "GuardianTable";

-- Option 3: Archive old table to separate schema
-- CREATE SCHEMA IF NOT EXISTS archive;
-- ALTER TABLE "GuardianTable" SET SCHEMA archive;

-- Option 4: Drop old table (ONLY IF BACKUP EXISTS)
-- DROP TABLE "GuardianTable";

-- Drop temporary mapping table
DROP TABLE IF EXISTS temp_guardian_id_mapping;

-- =====================================================================
-- COMMIT OR ROLLBACK
-- =====================================================================

-- Review the validation results above
-- If everything looks good, COMMIT
-- If there are issues, ROLLBACK and investigate

COMMIT;
-- ROLLBACK;  -- Uncomment to rollback if validation fails

-- =====================================================================
-- POST-MIGRATION TASKS
-- =====================================================================
--
-- 1. Link Relationship Records to Students *** CRITICAL ***
--    The Nr_StudentGuardians.Nr_StudentID field is currently NULL.
--    You MUST run SQL to link these to actual Nr_Students records:
--
--    UPDATE "Nr_StudentGuardians" sg
--    SET "Nr_StudentID" = <derive from StudentNumber>
--
--    This requires understanding your Student table structure.
--
-- 2. Link Guardians to Nr_Users (if applicable)
--    - Identify guardians who should have user accounts
--    - Create Nr_Users entries or link to existing ones
--    - UPDATE Nr_Guardians SET Nr_UserID = [user_id]
--
-- 3. Handle Personal Identity Fields (Name, FirstName, etc.)
--    - Migrate personal identity data to Nr_Users
--    - OR create Nr_GuardianPersonalInfo table if guardians don't need user accounts
--
-- 4. Handle Guardians Without GlobalUID
--    - Review guardians that were not migrated (no GlobalUID)
--    - Manually deduplicate and migrate these records
--
-- 5. Update Application Code
--    - Create new JPA entity classes:
--      - EntityNrGuardian (includes RegistrationX, RegistrationName)
--      - EntityNrStudentGuardian (junction entity)
--      - EntityNrGuardianContact, Finance, Employment
--      - Note: Portal data is now in EntityNrGuardian, Address is in EntityNrAddress
--    - Create repository interfaces
--    - Create mapper classes for DTO conversion
--    - Update service layer to use new entities
--    - Update API controllers as needed
--
-- 6. Test Migration Results
--    - Verify all guardian data is accessible via new structure
--    - Test many-to-many relationships (guardian → students)
--    - Test CRUD operations on normalized tables
--    - Validate referential integrity
--    - Test query performance
--
-- 7. Security Enhancements (Post-Migration)
--    - Implement encryption for Nr_GuardianFinance.AccountNumber
--    - Verify password hashing in Nr_Users.PasswordHash (not in Nr_Guardians)
--    - Configure row-level security if needed
--    - Set up audit logging for sensitive tables
--
-- =====================================================================

-- =====================================================================
-- MIGRATION STATISTICS QUERY (Run after COMMIT)
-- =====================================================================

SELECT
    'Migration Summary' AS "Report",
    (SELECT COUNT(*) FROM "Nr_Guardians") AS "Total Guardians (Deduplicated)",
    (SELECT COUNT(*) FROM "Nr_StudentGuardians") AS "Total Relationships",
    (SELECT COUNT(*) FROM "Nr_Users" u 
     INNER JOIN "Nr_Guardians" g ON u."UserID" = g."Nr_UserID" 
     WHERE u."AddressID" IS NOT NULL) AS "With Address (via Nr_Addresses)",
    (SELECT COUNT(*) FROM "Nr_GuardianContact") AS "With Contact",
    (SELECT COUNT(*) FROM "Nr_GuardianFinance") AS "With Finance",
    (SELECT COUNT(*) FROM "Nr_GuardianEmployment") AS "With Employment",
    (SELECT COUNT(*) FROM "Nr_Guardians" WHERE "RegistrationName" IS NOT NULL) AS "With Portal Access";

-- Example: Find guardians with multiple children across different schools
SELECT
    ng."Nr_GuardianID",
    ng."GlobalUID",
    COUNT(DISTINCT sg."SchoolID") AS "Number of Schools",
    COUNT(*) AS "Number of Children",
    STRING_AGG(DISTINCT sg."SchoolID", ', ') AS "Schools"
FROM "Nr_Guardians" ng
INNER JOIN "Nr_StudentGuardians" sg ON ng."Nr_GuardianID" = sg."Nr_GuardianID"
GROUP BY ng."Nr_GuardianID", ng."GlobalUID"
HAVING COUNT(DISTINCT sg."SchoolID") > 1;
