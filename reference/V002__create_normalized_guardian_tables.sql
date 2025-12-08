-- Migration: Create Normalized Guardian Module Tables
-- Description: Creates normalized tables for guardian module with many-to-many relationship pattern
-- Database: PostgreSQL
-- Date: 2025-01-14

-- Note: Flyway automatically wraps this migration in a transaction
-- No explicit BEGIN/COMMIT needed

-- ============================================================================
-- Phase 1: Create Normalized Guardian Tables (Identity + Relationships)
-- ============================================================================

-- Create Nr_Guardians table (Guardian identity - ONE per person)
CREATE TABLE IF NOT EXISTS "Nr_Guardians" (
    "Nr_GuardianID" INTEGER NOT NULL,
    "Nr_UserID" INTEGER,
    "GlobalUID" UUID,
    "XmoodID" UUID,
    "Salutation" CHARACTER VARYING(50),
    "Title" CHARACTER VARYING(20),
    "LetterSalutation" CHARACTER VARYING(50),
    "Timestamp" BYTEA NOT NULL,
    CONSTRAINT "Nr_Guardians_pkey" PRIMARY KEY ("Nr_GuardianID")
);

-- Create sequence for Nr_Guardians
CREATE SEQUENCE IF NOT EXISTS "Nr_Guardians_Nr_GuardianID_seq"
    AS INTEGER
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE "Nr_Guardians" ALTER COLUMN "Nr_GuardianID" SET DEFAULT nextval('"Nr_Guardians_Nr_GuardianID_seq"');
ALTER SEQUENCE "Nr_Guardians_Nr_GuardianID_seq" OWNED BY "Nr_Guardians"."Nr_GuardianID";

-- Create foreign key to Nr_Users
ALTER TABLE "Nr_Guardians"
    ADD CONSTRAINT "Nr_Guardians_Nr_UserID_fkey"
    FOREIGN KEY ("Nr_UserID") REFERENCES "Nr_Users"("UserID") ON DELETE SET NULL;

-- Create indexes
CREATE UNIQUE INDEX IF NOT EXISTS "idx_Nr_Guardians_GlobalUID" ON "Nr_Guardians"("GlobalUID") WHERE "GlobalUID" IS NOT NULL;
-- Note: XmoodID is NOT unique in source data - multiple guardians can have same XmoodID
CREATE INDEX IF NOT EXISTS "idx_Nr_Guardians_XmoodID" ON "Nr_Guardians"("XmoodID") WHERE "XmoodID" IS NOT NULL;
CREATE INDEX IF NOT EXISTS "idx_Nr_Guardians_Nr_UserID" ON "Nr_Guardians"("Nr_UserID");
-- Note: Tenant is obtained from Nr_Users."TenantID" via join, not stored in Nr_Guardians

-- Add table comment
COMMENT ON TABLE "Nr_Guardians" IS 'Guardian identity - ONE record per person. Does not contain student relationships (see Nr_StudentGuardians junction table). Tenant is obtained from linked Nr_Users."TenantID" via join.';
COMMENT ON COLUMN "Nr_Guardians"."Nr_UserID" IS 'Nullable reference to Nr_Users - guardian may not have user account. Primary contact (Email, Phone, Mobile, Fax) and TenantID should be in Nr_Users.';
COMMENT ON COLUMN "Nr_Guardians"."Salutation" IS 'Guardian salutation (e.g., Mr., Mrs., Ms., Dr.)';
COMMENT ON COLUMN "Nr_Guardians"."Title" IS 'Guardian title (e.g., Prof., Eng., etc.)';
COMMENT ON COLUMN "Nr_Guardians"."LetterSalutation" IS 'Formal salutation for letters and official correspondence';

-- ============================================================================
-- Phase 2: Create Nr_StudentGuardians (Junction Table - Many-to-Many)
-- ============================================================================

-- Create Nr_StudentGuardians table (Many-to-many relationship between Students and Guardians)
CREATE TABLE IF NOT EXISTS "Nr_StudentGuardians" (
    "Nr_StudentGuardianID" INTEGER NOT NULL,
    "Nr_StudentID" INTEGER,
    "Nr_GuardianID" INTEGER NOT NULL,
    "SchoolID" CHARACTER VARYING(10) NOT NULL,
    "Category" SMALLINT,
    "Priority" SMALLINT,
    "GuardianshipAuthorized" SMALLINT,
    "CustodyAuthorized" SMALLINT,
    "SameHousehold" SMALLINT,
    "FamilyCode" CHARACTER VARYING(10),
    "CompanyCarrier" SMALLINT,
    "Denomination" CHARACTER VARYING(3),
    "Addition" CHARACTER VARYING(200),
    "Remark" CHARACTER VARYING(255),
    "Tenant" SMALLINT NOT NULL,
    "Timestamp" BYTEA NOT NULL,
    CONSTRAINT "Nr_StudentGuardians_pkey" PRIMARY KEY ("Nr_StudentGuardianID")
);

-- Create sequence for Nr_StudentGuardians
CREATE SEQUENCE IF NOT EXISTS "Nr_StudentGuardians_Nr_StudentGuardianID_seq"
    AS INTEGER
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE "Nr_StudentGuardians" ALTER COLUMN "Nr_StudentGuardianID" SET DEFAULT nextval('"Nr_StudentGuardians_Nr_StudentGuardianID_seq"');
ALTER SEQUENCE "Nr_StudentGuardians_Nr_StudentGuardianID_seq" OWNED BY "Nr_StudentGuardians"."Nr_StudentGuardianID";

-- Create foreign key to Nr_Guardians
ALTER TABLE "Nr_StudentGuardians"
    ADD CONSTRAINT "Nr_StudentGuardians_Nr_GuardianID_fkey"
    FOREIGN KEY ("Nr_GuardianID") REFERENCES "Nr_Guardians"("Nr_GuardianID") ON DELETE CASCADE;

-- Note: Foreign key to Nr_Students will be added after Student table normalization

-- Create unique constraint to prevent duplicate relationships
CREATE UNIQUE INDEX IF NOT EXISTS "uq_Nr_StudentGuardians_Student_Guardian"
    ON "Nr_StudentGuardians"("Nr_StudentID", "Nr_GuardianID")
    WHERE "Nr_StudentID" IS NOT NULL;

-- Create indexes for common queries
CREATE INDEX IF NOT EXISTS "idx_Nr_StudentGuardians_Nr_StudentID" ON "Nr_StudentGuardians"("Nr_StudentID");
CREATE INDEX IF NOT EXISTS "idx_Nr_StudentGuardians_Nr_GuardianID" ON "Nr_StudentGuardians"("Nr_GuardianID");
CREATE INDEX IF NOT EXISTS "idx_Nr_StudentGuardians_SchoolID" ON "Nr_StudentGuardians"("SchoolID");
CREATE INDEX IF NOT EXISTS "idx_Nr_StudentGuardians_FamilyCode" ON "Nr_StudentGuardians"("FamilyCode");
CREATE INDEX IF NOT EXISTS "idx_Nr_StudentGuardians_Priority" ON "Nr_StudentGuardians"("Priority");
CREATE INDEX IF NOT EXISTS "idx_Nr_StudentGuardians_Tenant" ON "Nr_StudentGuardians"("Tenant");

-- Add table comment
COMMENT ON TABLE "Nr_StudentGuardians" IS 'Junction table managing many-to-many relationships between students and guardians. Contains relationship-specific metadata.';
COMMENT ON COLUMN "Nr_StudentGuardians"."Category" IS 'Guardian relationship type (e.g., Mother, Father, Legal Guardian, Emergency Contact)';
COMMENT ON COLUMN "Nr_StudentGuardians"."Priority" IS 'Contact priority order: 1=primary contact, 2=secondary, etc.';

-- ============================================================================
-- Phase 3: Create Supporting Guardian Tables
-- ============================================================================

-- Create Nr_GuardianAddress table
CREATE TABLE IF NOT EXISTS "Nr_GuardianAddress" (
    "Nr_GuardianAddressID" INTEGER NOT NULL,
    "Nr_GuardianID" INTEGER NOT NULL,
    "Street" CHARACTER VARYING(60),
    "PostalCode" CHARACTER VARYING(10),
    "Residence" CHARACTER VARYING(40),
    "Subdistrict" CHARACTER VARYING(50),
    "State" CHARACTER VARYING(3),
    "Country" CHARACTER VARYING(30),
    "CountryOfBirth" CHARACTER VARYING(30),
    "Country1" CHARACTER VARYING(30),
    "Country2" CHARACTER VARYING(30),
    CONSTRAINT "Nr_GuardianAddress_pkey" PRIMARY KEY ("Nr_GuardianAddressID")
);

-- Create sequence for Nr_GuardianAddress
CREATE SEQUENCE IF NOT EXISTS "Nr_GuardianAddress_Nr_GuardianAddressID_seq"
    AS INTEGER
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE "Nr_GuardianAddress" ALTER COLUMN "Nr_GuardianAddressID" SET DEFAULT nextval('"Nr_GuardianAddress_Nr_GuardianAddressID_seq"');
ALTER SEQUENCE "Nr_GuardianAddress_Nr_GuardianAddressID_seq" OWNED BY "Nr_GuardianAddress"."Nr_GuardianAddressID";

-- Create foreign key to Nr_Guardians
ALTER TABLE "Nr_GuardianAddress"
    ADD CONSTRAINT "Nr_GuardianAddress_Nr_GuardianID_fkey"
    FOREIGN KEY ("Nr_GuardianID") REFERENCES "Nr_Guardians"("Nr_GuardianID") ON DELETE CASCADE;

-- Create unique index (one address per guardian)
CREATE UNIQUE INDEX IF NOT EXISTS "uq_Nr_GuardianAddress_GuardianID" ON "Nr_GuardianAddress"("Nr_GuardianID");
CREATE INDEX IF NOT EXISTS "idx_Nr_GuardianAddress_PostalCode" ON "Nr_GuardianAddress"("PostalCode");
CREATE INDEX IF NOT EXISTS "idx_Nr_GuardianAddress_Country" ON "Nr_GuardianAddress"("Country");

COMMENT ON TABLE "Nr_GuardianAddress" IS 'Guardian address data - ONE per guardian, shared across all their children';

-- Create Nr_GuardianContact table (SECONDARY contact methods only)
CREATE TABLE IF NOT EXISTS "Nr_GuardianContact" (
    "Nr_GuardianContactID" INTEGER NOT NULL,
    "Nr_GuardianID" INTEGER NOT NULL,
    "Phone2" CHARACTER VARYING(25),
    "MobileNumber2" CHARACTER VARYING(30),
    CONSTRAINT "Nr_GuardianContact_pkey" PRIMARY KEY ("Nr_GuardianContactID")
);

-- Create sequence for Nr_GuardianContact
CREATE SEQUENCE IF NOT EXISTS "Nr_GuardianContact_Nr_GuardianContactID_seq"
    AS INTEGER
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE "Nr_GuardianContact" ALTER COLUMN "Nr_GuardianContactID" SET DEFAULT nextval('"Nr_GuardianContact_Nr_GuardianContactID_seq"');
ALTER SEQUENCE "Nr_GuardianContact_Nr_GuardianContactID_seq" OWNED BY "Nr_GuardianContact"."Nr_GuardianContactID";

-- Create foreign key to Nr_Guardians
ALTER TABLE "Nr_GuardianContact"
    ADD CONSTRAINT "Nr_GuardianContact_Nr_GuardianID_fkey"
    FOREIGN KEY ("Nr_GuardianID") REFERENCES "Nr_Guardians"("Nr_GuardianID") ON DELETE CASCADE;

-- Create unique index (one contact record per guardian)
CREATE UNIQUE INDEX IF NOT EXISTS "uq_Nr_GuardianContact_GuardianID" ON "Nr_GuardianContact"("Nr_GuardianID");
CREATE INDEX IF NOT EXISTS "idx_Nr_GuardianContact_Phone2" ON "Nr_GuardianContact"("Phone2");
CREATE INDEX IF NOT EXISTS "idx_Nr_GuardianContact_MobileNumber2" ON "Nr_GuardianContact"("MobileNumber2");

COMMENT ON TABLE "Nr_GuardianContact" IS 'Guardian SECONDARY contact data only. Primary contact (Email, Phone, Mobile, Fax) stored in Nr_Users.';
COMMENT ON COLUMN "Nr_GuardianContact"."Phone2" IS 'Secondary phone. Primary phone in Nr_Users.Phone';
COMMENT ON COLUMN "Nr_GuardianContact"."MobileNumber2" IS 'Secondary mobile. Primary mobile in Nr_Users.Mobile';

-- Create Nr_GuardianFinance table (GDPR Sensitive)
CREATE TABLE IF NOT EXISTS "Nr_GuardianFinance" (
    "Nr_GuardianFinanceID" INTEGER NOT NULL,
    "Nr_GuardianID" INTEGER NOT NULL,
    "FinancialInstitution" CHARACTER VARYING(50),
    "BankCode" CHARACTER VARYING(15),
    "AccountNumber" CHARACTER VARYING(34),
    "DebtorNumber" CHARACTER VARYING(30),
    CONSTRAINT "Nr_GuardianFinance_pkey" PRIMARY KEY ("Nr_GuardianFinanceID")
);

-- Create sequence for Nr_GuardianFinance
CREATE SEQUENCE IF NOT EXISTS "Nr_GuardianFinance_Nr_GuardianFinanceID_seq"
    AS INTEGER
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE "Nr_GuardianFinance" ALTER COLUMN "Nr_GuardianFinanceID" SET DEFAULT nextval('"Nr_GuardianFinance_Nr_GuardianFinanceID_seq"');
ALTER SEQUENCE "Nr_GuardianFinance_Nr_GuardianFinanceID_seq" OWNED BY "Nr_GuardianFinance"."Nr_GuardianFinanceID";

-- Create foreign key to Nr_Guardians
ALTER TABLE "Nr_GuardianFinance"
    ADD CONSTRAINT "Nr_GuardianFinance_Nr_GuardianID_fkey"
    FOREIGN KEY ("Nr_GuardianID") REFERENCES "Nr_Guardians"("Nr_GuardianID") ON DELETE CASCADE;

-- Create unique index (one finance record per guardian)
CREATE UNIQUE INDEX IF NOT EXISTS "uq_Nr_GuardianFinance_GuardianID" ON "Nr_GuardianFinance"("Nr_GuardianID");

COMMENT ON TABLE "Nr_GuardianFinance" IS 'GDPR SENSITIVE: Guardian financial data - requires enhanced security controls. ONE per guardian.';
COMMENT ON COLUMN "Nr_GuardianFinance"."AccountNumber" IS 'SENSITIVE: IBAN or account number - must be encrypted at rest';

-- Create Nr_GuardianEmployment table
CREATE TABLE IF NOT EXISTS "Nr_GuardianEmployment" (
    "Nr_GuardianEmploymentID" INTEGER NOT NULL,
    "Nr_GuardianID" INTEGER NOT NULL,
    "Company" CHARACTER VARYING(100),
    "Profession" CHARACTER VARYING(50),
    CONSTRAINT "Nr_GuardianEmployment_pkey" PRIMARY KEY ("Nr_GuardianEmploymentID")
);

-- Create sequence for Nr_GuardianEmployment
CREATE SEQUENCE IF NOT EXISTS "Nr_GuardianEmployment_Nr_GuardianEmploymentID_seq"
    AS INTEGER
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE "Nr_GuardianEmployment" ALTER COLUMN "Nr_GuardianEmploymentID" SET DEFAULT nextval('"Nr_GuardianEmployment_Nr_GuardianEmploymentID_seq"');
ALTER SEQUENCE "Nr_GuardianEmployment_Nr_GuardianEmploymentID_seq" OWNED BY "Nr_GuardianEmployment"."Nr_GuardianEmploymentID";

-- Create foreign key to Nr_Guardians
ALTER TABLE "Nr_GuardianEmployment"
    ADD CONSTRAINT "Nr_GuardianEmployment_Nr_GuardianID_fkey"
    FOREIGN KEY ("Nr_GuardianID") REFERENCES "Nr_Guardians"("Nr_GuardianID") ON DELETE CASCADE;

-- Create unique index (one employment record per guardian)
CREATE UNIQUE INDEX IF NOT EXISTS "uq_Nr_GuardianEmployment_GuardianID" ON "Nr_GuardianEmployment"("Nr_GuardianID");

COMMENT ON TABLE "Nr_GuardianEmployment" IS 'Guardian employment data - ONE per guardian, shared across all their children';

-- Create Nr_GuardianPortal table (Security Sensitive)
-- Note: Password is stored in Nr_Users table, not here
CREATE TABLE IF NOT EXISTS "Nr_GuardianPortal" (
    "Nr_GuardianPortalID" INTEGER NOT NULL,
    "Nr_GuardianID" INTEGER NOT NULL,
    "RegistrationX" SMALLINT,
    "RegistrationName" CHARACTER VARYING(20),
    CONSTRAINT "Nr_GuardianPortal_pkey" PRIMARY KEY ("Nr_GuardianPortalID")
);

-- Create sequence for Nr_GuardianPortal
CREATE SEQUENCE IF NOT EXISTS "Nr_GuardianPortal_Nr_GuardianPortalID_seq"
    AS INTEGER
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE "Nr_GuardianPortal" ALTER COLUMN "Nr_GuardianPortalID" SET DEFAULT nextval('"Nr_GuardianPortal_Nr_GuardianPortalID_seq"');
ALTER SEQUENCE "Nr_GuardianPortal_Nr_GuardianPortalID_seq" OWNED BY "Nr_GuardianPortal"."Nr_GuardianPortalID";

-- Create foreign key to Nr_Guardians
ALTER TABLE "Nr_GuardianPortal"
    ADD CONSTRAINT "Nr_GuardianPortal_Nr_GuardianID_fkey"
    FOREIGN KEY ("Nr_GuardianID") REFERENCES "Nr_Guardians"("Nr_GuardianID") ON DELETE CASCADE;

-- Create unique index (one portal record per guardian)
CREATE UNIQUE INDEX IF NOT EXISTS "uq_Nr_GuardianPortal_GuardianID" ON "Nr_GuardianPortal"("Nr_GuardianID");
CREATE UNIQUE INDEX IF NOT EXISTS "uq_Nr_GuardianPortal_RegistrationName" ON "Nr_GuardianPortal"("RegistrationName")
    WHERE "RegistrationName" IS NOT NULL;

COMMENT ON TABLE "Nr_GuardianPortal" IS 'SECURITY SENSITIVE: Guardian portal registration data. Password is stored in Nr_Users table.';

-- ============================================================================
-- Phase 4: Migrate Data from GuardianTable to Normalized Tables
-- ============================================================================

-- IMPORTANT: This migration uses GlobalUID to deduplicate guardians
-- Guardians with multiple children will have ONE guardian identity record
-- and MULTIPLE relationship records in Nr_StudentGuardians

-- Step 1: Migrate guardian identity (DEDUPLICATED by GlobalUID)
-- Note: Tenant is NOT migrated here - it will be obtained from Nr_Users."TenantID" via join
INSERT INTO "Nr_Guardians" (
    "Nr_UserID",
    "GlobalUID",
    "XmoodID",
    "Salutation",
    "Title",
    "LetterSalutation",
    "Timestamp"
)
SELECT DISTINCT ON (g."GlobalUID")
    NULL AS "Nr_UserID",  -- Will be linked later after creating Nr_Users entries
    g."GlobalUID",
    g."XmoodID",
    g."Salutation",
    g."Title",
    g."LetterSalutation",
    g."Timestamp"
FROM "GuardianTable" g
WHERE g."GlobalUID" IS NOT NULL
AND NOT EXISTS (
    SELECT 1 FROM "Nr_Guardians" ng WHERE ng."GlobalUID" = g."GlobalUID"
)
ORDER BY g."GlobalUID", g."ID";

-- Step 2: Create Nr_Users entries with auto-generated LoginNames
-- LoginName format: <first_initial>.<lastname> (e.g., j.doe for John Doe)
-- Handles duplicates by adding numbers: j.doe, j.doe2, j.doe3, etc.
-- Primary contact data (Email, Phone, Mobile/MobileNumber, Fax) migrated here

-- Create temporary function to generate unique LoginNames
CREATE OR REPLACE FUNCTION generate_unique_loginname(
    p_firstname VARCHAR,
    p_lastname VARCHAR
) RETURNS VARCHAR AS $$
DECLARE
    v_base_loginname VARCHAR(20);
    v_loginname VARCHAR(20);
    v_counter INTEGER := 1;
BEGIN
    -- Handle NULL or empty names
    IF p_firstname IS NULL OR p_firstname = '' OR p_lastname IS NULL OR p_lastname = '' THEN
        RETURN NULL;
    END IF;

    -- Generate base loginname: first_initial.lastname (lowercase, no spaces)
    v_base_loginname := LOWER(
        SUBSTRING(REGEXP_REPLACE(p_firstname, '[^a-zA-Z]', '', 'g') FROM 1 FOR 1) ||
        '.' ||
        REGEXP_REPLACE(p_lastname, '[^a-zA-Z]', '', 'g')
    );

    -- Truncate to max 20 characters (LoginName field limit)
    v_base_loginname := SUBSTRING(v_base_loginname FROM 1 FOR 20);

    v_loginname := v_base_loginname;

    -- Check for duplicates and add counter if needed
    WHILE EXISTS (SELECT 1 FROM "Nr_Users" WHERE "LoginName" = v_loginname) LOOP
        v_counter := v_counter + 1;
        -- Format: j.doe2, j.doe3, etc. (ensure we don't exceed 20 chars)
        v_loginname := SUBSTRING(v_base_loginname FROM 1 FOR (20 - LENGTH(v_counter::TEXT))) || v_counter::TEXT;
    END LOOP;

    RETURN v_loginname;
END;
$$ LANGUAGE plpgsql;

-- Create Nr_Users entries for guardians with auto-generated LoginNames
INSERT INTO "Nr_Users" (
    "LoginName",
    "FirstName",
    "LastName",
    "Email",
    "Phone",
    "Mobile",
    "Fax",
    "SchoolID",
    "TenantID",
    "LastModified"
)
SELECT DISTINCT ON (g."GlobalUID")
    generate_unique_loginname(g."FirstName", g."Name") AS "LoginName",
    g."FirstName",
    g."Name" AS "LastName",
    g."Email",
    g."Phone",
    g."MobileNumber" AS "Mobile",  -- Note: GuardianTable uses MobileNumber, Nr_Users uses Mobile
    g."Fax",
    g."SchoolID",
    g."Tenant" AS "TenantID",
    CURRENT_TIMESTAMP AS "LastModified"
FROM "GuardianTable" g
WHERE g."GlobalUID" IS NOT NULL
AND g."Name" IS NOT NULL AND g."Name" != ''
AND g."FirstName" IS NOT NULL AND g."FirstName" != ''
AND NOT EXISTS (
    SELECT 1 FROM "Nr_Guardians" ng
    INNER JOIN "Nr_Users" u ON ng."Nr_UserID" = u."UserID"
    WHERE ng."GlobalUID" = g."GlobalUID"
)
ORDER BY g."GlobalUID", g."ID"
ON CONFLICT ("LoginName") WHERE "LoginName" IS NOT NULL DO NOTHING;

-- Step 3: Link Nr_Guardians to newly created Nr_Users
UPDATE "Nr_Guardians" ng
SET "Nr_UserID" = u."UserID"
FROM "GuardianTable" g
INNER JOIN "Nr_Users" u ON (
    u."FirstName" = g."FirstName"
    AND u."LastName" = g."Name"
    AND u."TenantID" = g."Tenant"
    AND (u."Email" = g."Email" OR (u."Email" IS NULL AND g."Email" IS NULL))
)
WHERE ng."GlobalUID" = g."GlobalUID"
AND ng."Nr_UserID" IS NULL;

-- Clean up temporary function
DROP FUNCTION IF EXISTS generate_unique_loginname(VARCHAR, VARCHAR);

-- Step 4: Migrate relationship records (ONE per guardian-student pair)
-- Note: Links Nr_StudentID directly during INSERT by joining to Students → Nr_Students
-- Uses DISTINCT ON to handle duplicate records in GuardianTable
INSERT INTO "Nr_StudentGuardians" (
    "Nr_StudentID",
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
SELECT DISTINCT ON (ng."Nr_GuardianID", s."ID", g."SchoolID")
    -- Link Nr_StudentID directly: Students.ID was copied to Nr_Students.Nr_StudentID
    s."ID" AS "Nr_StudentID",  -- GuardianTable.StudentNumber → Students.ID = Nr_Students.Nr_StudentID
    ng."Nr_GuardianID",
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
INNER JOIN "Nr_Guardians" ng ON ng."GlobalUID" = g."GlobalUID"
-- Join to Students: GuardianTable.StudentNumber = Students.ID
-- Since Students.ID = Nr_Students.Nr_StudentID, we can use s."ID" directly
LEFT JOIN "Students" s ON g."StudentNumber" = s."ID"
WHERE g."GlobalUID" IS NOT NULL
-- Order by ID to get the first/oldest record in case of duplicates
ORDER BY ng."Nr_GuardianID", s."ID", g."SchoolID", g."ID"
ON CONFLICT ("Nr_StudentID", "Nr_GuardianID") WHERE "Nr_StudentID" IS NOT NULL DO NOTHING;

-- Step 5: Migrate address data (ONE per guardian, deduplicated)
INSERT INTO "Nr_GuardianAddress" (
    "Nr_GuardianID",
    "Street",
    "PostalCode",
    "Residence",
    "Subdistrict",
    "State",
    "Country",
    "CountryOfBirth",
    "Country1",
    "Country2"
)
SELECT DISTINCT ON (ng."Nr_GuardianID")
    ng."Nr_GuardianID",
    g."Street",
    g."PostalCode",
    g."Residence",
    g."Subdistrict",
    g."State",
    g."Country",
    g."CountryOfBirth",
    g."Country1",
    g."Country2"
FROM "GuardianTable" g
INNER JOIN "Nr_Guardians" ng ON ng."GlobalUID" = g."GlobalUID"
WHERE g."GlobalUID" IS NOT NULL
AND (g."Street" IS NOT NULL OR g."PostalCode" IS NOT NULL OR g."Residence" IS NOT NULL)
AND NOT EXISTS (
    SELECT 1 FROM "Nr_GuardianAddress" na WHERE na."Nr_GuardianID" = ng."Nr_GuardianID"
)
ORDER BY ng."Nr_GuardianID", g."ID";

-- Step 6: Migrate secondary contact data (ONE per guardian, deduplicated)
-- Note: Primary contact (Email, Phone, Mobile, Fax) already migrated to Nr_Users in Step 2
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
INNER JOIN "Nr_Guardians" ng ON ng."GlobalUID" = g."GlobalUID"
WHERE g."GlobalUID" IS NOT NULL
AND (g."Phone2" IS NOT NULL OR g."MobileNumber2" IS NOT NULL)
AND NOT EXISTS (
    SELECT 1 FROM "Nr_GuardianContact" nc WHERE nc."Nr_GuardianID" = ng."Nr_GuardianID"
)
ORDER BY ng."Nr_GuardianID", g."ID";

-- Step 7: Migrate financial data (ONE per guardian, deduplicated) - GDPR Sensitive
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
INNER JOIN "Nr_Guardians" ng ON ng."GlobalUID" = g."GlobalUID"
WHERE g."GlobalUID" IS NOT NULL
AND (g."FinancialInstitution" IS NOT NULL OR g."BankCode" IS NOT NULL OR g."AccountNumber" IS NOT NULL)
AND NOT EXISTS (
    SELECT 1 FROM "Nr_GuardianFinance" nf WHERE nf."Nr_GuardianID" = ng."Nr_GuardianID"
)
ORDER BY ng."Nr_GuardianID", g."ID";

-- Step 8: Migrate employment data (ONE per guardian, deduplicated)
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
INNER JOIN "Nr_Guardians" ng ON ng."GlobalUID" = g."GlobalUID"
WHERE g."GlobalUID" IS NOT NULL
AND (g."Company" IS NOT NULL OR g."Profession" IS NOT NULL)
AND NOT EXISTS (
    SELECT 1 FROM "Nr_GuardianEmployment" ne WHERE ne."Nr_GuardianID" = ng."Nr_GuardianID"
)
ORDER BY ng."Nr_GuardianID", g."ID";

-- Step 9: Migrate portal data (ONE per guardian, deduplicated) - Security Sensitive
-- Note: Handle duplicate RegistrationName conflicts using window function
-- First guardian with a username gets it, others get NULL RegistrationName
-- Password is NOT migrated here - it's stored in Nr_Users table
INSERT INTO "Nr_GuardianPortal" (
    "Nr_GuardianID",
    "RegistrationX",
    "RegistrationName"
)
WITH guardian_portal_ranked AS (
    SELECT DISTINCT ON (ng."Nr_GuardianID")
        ng."Nr_GuardianID",
        g."RegistrationX",
        g."RegistrationName",
        -- Rank guardians with same RegistrationName (first one gets rank 1)
        ROW_NUMBER() OVER (
            PARTITION BY g."RegistrationName"
            ORDER BY ng."Nr_GuardianID"
        ) AS rn
    FROM "GuardianTable" g
    INNER JOIN "Nr_Guardians" ng ON ng."GlobalUID" = g."GlobalUID"
    WHERE g."GlobalUID" IS NOT NULL
    AND (g."RegistrationX" IS NOT NULL OR g."RegistrationName" IS NOT NULL)
    ORDER BY ng."Nr_GuardianID", g."ID"
)
SELECT
    "Nr_GuardianID",
    "RegistrationX",
    -- Only assign RegistrationName to first guardian with that username
    CASE
        WHEN rn = 1 THEN "RegistrationName"
        ELSE NULL  -- Duplicate username - set to NULL for manual review
    END AS "RegistrationName"
FROM guardian_portal_ranked
WHERE NOT EXISTS (
    SELECT 1 FROM "Nr_GuardianPortal" np WHERE np."Nr_GuardianID" = guardian_portal_ranked."Nr_GuardianID"
);

-- ============================================================================
-- Post-Migration Validation Queries
-- ============================================================================

-- Uncomment to validate migration:

-- Total guardians
-- SELECT COUNT(*) AS total_guardian_records FROM "GuardianTable";
-- SELECT COUNT(DISTINCT "GlobalUID") AS unique_guardians FROM "GuardianTable" WHERE "GlobalUID" IS NOT NULL;
-- SELECT COUNT(*) AS migrated_guardians FROM "Nr_Guardians";

-- Relationships
-- SELECT COUNT(*) AS total_relationships FROM "Nr_StudentGuardians";

-- Supporting tables
-- SELECT COUNT(*) AS with_address FROM "Nr_GuardianAddress";
-- SELECT COUNT(*) AS with_contact FROM "Nr_GuardianContact";
-- SELECT COUNT(*) AS with_finance FROM "Nr_GuardianFinance";
-- SELECT COUNT(*) AS with_employment FROM "Nr_GuardianEmployment";
-- SELECT COUNT(*) AS with_portal FROM "Nr_GuardianPortal";

-- Guardians with multiple children
-- SELECT ng."Nr_GuardianID", COUNT(*) as children_count
-- FROM "Nr_StudentGuardians" sg
-- INNER JOIN "Nr_Guardians" ng ON sg."Nr_GuardianID" = ng."Nr_GuardianID"
-- GROUP BY ng."Nr_GuardianID"
-- HAVING COUNT(*) > 1;

-- Guardians with username conflicts (RegistrationName set to NULL due to duplicates)
-- SELECT ng."Nr_GuardianID", ng."GlobalUID", u."FirstName", u."LastName", u."Email"
-- FROM "Nr_GuardianPortal" gp
-- INNER JOIN "Nr_Guardians" ng ON gp."Nr_GuardianID" = ng."Nr_GuardianID"
-- LEFT JOIN "Nr_Users" u ON ng."Nr_UserID" = u."UserID"
-- WHERE gp."RegistrationName" IS NULL
-- AND gp."RegistrationX" IS NOT NULL;

-- Duplicate RegistrationNames in source data (for manual review)
-- SELECT g."RegistrationName", COUNT(DISTINCT g."GlobalUID") as guardian_count
-- FROM "GuardianTable" g
-- WHERE g."RegistrationName" IS NOT NULL
-- AND g."GlobalUID" IS NOT NULL
-- GROUP BY g."RegistrationName"
-- HAVING COUNT(DISTINCT g."GlobalUID") > 1
-- ORDER BY guardian_count DESC;

-- Note: Flyway automatically commits the transaction
