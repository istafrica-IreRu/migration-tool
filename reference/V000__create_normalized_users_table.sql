-- Migration: Create Normalized Users Table
-- Description: Creates the foundational Nr_Users table for personal information (students, teachers, guardians, applicants)
-- Database: PostgreSQL
-- Date: 2025-01-27

-- Note: Flyway automatically wraps this migration in a transaction
-- No explicit BEGIN/COMMIT needed

-- ============================================================================
-- Phase 1: Create Nr_Users Table (Base reference table for personal information)
-- ============================================================================

-- This table contains personal information for students, teachers, guardians, and applicants
-- It is referenced by Nr_Students, Nr_Teachers, Nr_Guardians, and Nr_Applicants tables

CREATE TABLE IF NOT EXISTS "Nr_Users" (
    "UserID" INTEGER NOT NULL,
    "LoginName" CHARACTER VARYING(20),
    "FirstName" CHARACTER VARYING(100),
    "LastName" CHARACTER VARYING(100),
    "BirthName" CHARACTER VARYING(100),
    "NameAddition" CHARACTER VARYING(50),
    "BirthDate" DATE,
    "BirthPlace" CHARACTER VARYING(100),
    "Gender" SMALLINT,
    "NationalityID" INTEGER,                  -- Foreign Key to Nationalities table (if exists)
    "Email" CHARACTER VARYING(150),
    "Phone" CHARACTER VARYING(25),
    "Mobile" CHARACTER VARYING(25),
    "Fax" CHARACTER VARYING(25),
    "PhotoFile" CHARACTER VARYING(255),
    "Address" CHARACTER VARYING(255),
    "City" CHARACTER VARYING(100),
    "PostalCode" CHARACTER VARYING(20),
    "Country" CHARACTER VARYING(50),
    "SchoolID" CHARACTER VARYING(10),
    "TenantID" SMALLINT,
    "GlobalUID" UUID,
    "LastModified" TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "Nr_Users_pkey" PRIMARY KEY ("UserID")
);

-- Create sequence for Nr_Users
CREATE SEQUENCE IF NOT EXISTS "Nr_Users_UserID_seq"
    AS INTEGER
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE "Nr_Users" ALTER COLUMN "UserID" SET DEFAULT nextval('"Nr_Users_UserID_seq"');
ALTER SEQUENCE "Nr_Users_UserID_seq" OWNED BY "Nr_Users"."UserID";

-- Create unique constraint on LoginName (if not null)
CREATE UNIQUE INDEX IF NOT EXISTS "uq_Nr_Users_LoginName" 
    ON "Nr_Users"("LoginName") 
    WHERE "LoginName" IS NOT NULL;

-- Create unique constraint on GlobalUID (if not null)
CREATE UNIQUE INDEX IF NOT EXISTS "uq_Nr_Users_GlobalUID" 
    ON "Nr_Users"("GlobalUID") 
    WHERE "GlobalUID" IS NOT NULL;

-- Create indexes for common queries
CREATE INDEX IF NOT EXISTS "idx_Nr_Users_Email" ON "Nr_Users"("Email");
CREATE INDEX IF NOT EXISTS "idx_Nr_Users_LastName" ON "Nr_Users"("LastName");
CREATE INDEX IF NOT EXISTS "idx_Nr_Users_FirstName" ON "Nr_Users"("FirstName");
CREATE INDEX IF NOT EXISTS "idx_Nr_Users_SchoolID" ON "Nr_Users"("SchoolID");
CREATE INDEX IF NOT EXISTS "idx_Nr_Users_TenantID" ON "Nr_Users"("TenantID");

-- Add table and column comments
COMMENT ON TABLE "Nr_Users" IS 'Base reference table for personal information. Contains data for students, teachers, guardians, and applicants. Referenced by Nr_Students, Nr_Teachers, Nr_Guardians, and Nr_Applicants.';
COMMENT ON COLUMN "Nr_Users"."UserID" IS 'Primary key - unique identifier for each user';
COMMENT ON COLUMN "Nr_Users"."LoginName" IS 'Unique login name for portal access (nullable)';
COMMENT ON COLUMN "Nr_Users"."FirstName" IS 'User first name';
COMMENT ON COLUMN "Nr_Users"."LastName" IS 'User last name';
COMMENT ON COLUMN "Nr_Users"."BirthName" IS 'Birth name (maiden name) if different from current last name';
COMMENT ON COLUMN "Nr_Users"."NameAddition" IS 'Name addition (e.g., von, de, etc.)';
COMMENT ON COLUMN "Nr_Users"."BirthDate" IS 'Date of birth';
COMMENT ON COLUMN "Nr_Users"."BirthPlace" IS 'Place of birth';
COMMENT ON COLUMN "Nr_Users"."Gender" IS 'Gender (0=unknown, 1=male, 2=female, 3=diverse)';
COMMENT ON COLUMN "Nr_Users"."NationalityID" IS 'Foreign key to Nationalities table (if exists)';
COMMENT ON COLUMN "Nr_Users"."Email" IS 'Primary email address';
COMMENT ON COLUMN "Nr_Users"."Phone" IS 'Primary phone number';
COMMENT ON COLUMN "Nr_Users"."Mobile" IS 'Primary mobile number';
COMMENT ON COLUMN "Nr_Users"."Fax" IS 'Fax number';
COMMENT ON COLUMN "Nr_Users"."PhotoFile" IS 'Path to user photo file';
COMMENT ON COLUMN "Nr_Users"."Address" IS 'Street address';
COMMENT ON COLUMN "Nr_Users"."City" IS 'City of residence';
COMMENT ON COLUMN "Nr_Users"."PostalCode" IS 'Postal/ZIP code';
COMMENT ON COLUMN "Nr_Users"."Country" IS 'Country of residence';
COMMENT ON COLUMN "Nr_Users"."SchoolID" IS 'School identifier for multi-school systems';
COMMENT ON COLUMN "Nr_Users"."TenantID" IS 'Tenant identifier for multi-tenant systems';
COMMENT ON COLUMN "Nr_Users"."GlobalUID" IS 'Global unique identifier (UUID)';
COMMENT ON COLUMN "Nr_Users"."LastModified" IS 'Timestamp of last modification';

-- Note: Flyway automatically commits the transaction
