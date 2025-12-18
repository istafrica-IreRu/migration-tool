-- Migration: Create Normalized Enrollment Module Tables
-- Description: Creates normalized tables for enrollment module following 3NF and Student module patterns
-- Database: PostgreSQL
-- Date: 2024

-- Note: Flyway automatically wraps this migration in a transaction
-- No explicit BEGIN/COMMIT needed

-- ============================================================================
-- Phase 1: Normalize ApplicantTable
-- ============================================================================

-- Create Nr_Applicants table (Core applicant administrative data - NO names, NO SchoolID, NO Tenant, NO Country)
CREATE TABLE IF NOT EXISTS "Nr_Applicants" (
    "Nr_ApplicantID" INTEGER NOT NULL,
    "Nr_UserID" INTEGER NOT NULL,
    "Disability" SMALLINT,
    "MotherTongue" CHARACTER VARYING(10),
    "GUID" UUID,
    "Timestamp" BYTEA NOT NULL,
    CONSTRAINT "Nr_Applicants_pkey" PRIMARY KEY ("Nr_ApplicantID")
);

-- Create sequence for Nr_Applicants
CREATE SEQUENCE IF NOT EXISTS "Nr_Applicants_Nr_ApplicantID_seq"
    AS INTEGER
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE "Nr_Applicants" ALTER COLUMN "Nr_ApplicantID" SET DEFAULT nextval('"Nr_Applicants_Nr_ApplicantID_seq"');
ALTER SEQUENCE "Nr_Applicants_Nr_ApplicantID_seq" OWNED BY "Nr_Applicants"."Nr_ApplicantID";

-- Create foreign key to Nr_Users
ALTER TABLE "Nr_Applicants"
    ADD CONSTRAINT "Nr_Applicants_Nr_UserID_fkey" 
    FOREIGN KEY ("Nr_UserID") REFERENCES "Nr_Users"("UserID") ON DELETE RESTRICT;

-- Create indexes
CREATE INDEX IF NOT EXISTS "idx_Nr_Applicants_Nr_UserID" ON "Nr_Applicants"("Nr_UserID");
CREATE INDEX IF NOT EXISTS "idx_Nr_Applicants_GUID" ON "Nr_Applicants"("GUID");

-- Note: Nr_ApplicantAddress table removed - addresses are now stored in Nr_Addresses table (User module)
-- Note: Nr_ApplicantContact table removed - contact data (email, phone, mobile, fax) is now in Nr_Users table

-- Create Nr_ApplicantApplicationInfo table
CREATE TABLE IF NOT EXISTS "Nr_ApplicantApplicationInfo" (
    "Nr_ApplicationInfoID" INTEGER NOT NULL,
    "Nr_ApplicantID" INTEGER,
    "Class" CHARACTER VARYING(10),
    "TrainingCompany" CHARACTER VARYING(20),
    "FormSuffix" CHARACTER VARYING(3),
    "GuestStudent" SMALLINT,
    "AdmissionDate" TIMESTAMP WITHOUT TIME ZONE,
    "CompanyLock" SMALLINT,
    CONSTRAINT "Nr_ApplicantApplicationInfo_pkey" PRIMARY KEY ("Nr_ApplicationInfoID")
);

-- Create sequence for Nr_ApplicantApplicationInfo
CREATE SEQUENCE IF NOT EXISTS "Nr_ApplicantApplicationInfo_Nr_ApplicationInfoID_seq"
    AS INTEGER
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE "Nr_ApplicantApplicationInfo" ALTER COLUMN "Nr_ApplicationInfoID" SET DEFAULT nextval('"Nr_ApplicantApplicationInfo_Nr_ApplicationInfoID_seq"');
ALTER SEQUENCE "Nr_ApplicantApplicationInfo_Nr_ApplicationInfoID_seq" OWNED BY "Nr_ApplicantApplicationInfo"."Nr_ApplicationInfoID";

-- Create foreign key to Nr_Applicants
ALTER TABLE "Nr_ApplicantApplicationInfo"
    ADD CONSTRAINT "Nr_ApplicantApplicationInfo_Nr_ApplicantID_fkey" 
    FOREIGN KEY ("Nr_ApplicantID") REFERENCES "Nr_Applicants"("Nr_ApplicantID") ON DELETE CASCADE;

-- Create index
CREATE INDEX IF NOT EXISTS "idx_Nr_ApplicantApplicationInfo_Nr_ApplicantID" ON "Nr_ApplicantApplicationInfo"("Nr_ApplicantID");

-- ============================================================================
-- Phase 2: Normalize ApplicantGuardianTable
-- ============================================================================

-- Create Nr_ApplicantGuardians table (Core guardian relationship data - NO names, NO SchoolID, NO Tenant, NO Country)
-- Note: Portal registration data (RegistrationX, RegistrationName) is now directly in this table
CREATE TABLE IF NOT EXISTS "Nr_ApplicantGuardians" (
    "Nr_GuardianID" INTEGER NOT NULL,
    "Nr_ApplicantID" INTEGER,
    "Nr_UserID" INTEGER NOT NULL,
    "StudentNumber" INTEGER,
    "Category" SMALLINT,
    "Priority" SMALLINT,
    "Salutation" CHARACTER VARYING(255),
    "LetterSalutation" CHARACTER VARYING(255),
    "Title" CHARACTER VARYING(255),
    "Addition" CHARACTER VARYING(255),
    "Profession" CHARACTER VARYING(255),
    "Denomination" CHARACTER VARYING(255),
    "CountryOfBirth" CHARACTER VARYING(255),
    "GuardianshipAuthorized" SMALLINT,
    "CustodyAuthorized" SMALLINT,
    "SameHousehold" SMALLINT,
    "CompanyCarrier" SMALLINT,
    "FamilyCode" CHARACTER VARYING(255),
    "Remark" CHARACTER VARYING(255),
    "Phone2" CHARACTER VARYING(255),
    "MobileNumber2" CHARACTER VARYING(255),
    "GUID" UUID,
    "XmoodID" UUID,
    "GlobalUID" UUID,
    "RegistrationX" SMALLINT,
    "RegistrationName" CHARACTER VARYING(255),
    "Timestamp" BYTEA NOT NULL,
    CONSTRAINT "Nr_ApplicantGuardians_pkey" PRIMARY KEY ("Nr_GuardianID")
);

-- Create sequence for Nr_ApplicantGuardians
CREATE SEQUENCE IF NOT EXISTS "Nr_ApplicantGuardians_Nr_GuardianID_seq"
    AS INTEGER
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE "Nr_ApplicantGuardians" ALTER COLUMN "Nr_GuardianID" SET DEFAULT nextval('"Nr_ApplicantGuardians_Nr_GuardianID_seq"');
ALTER SEQUENCE "Nr_ApplicantGuardians_Nr_GuardianID_seq" OWNED BY "Nr_ApplicantGuardians"."Nr_GuardianID";

-- Create foreign keys
ALTER TABLE "Nr_ApplicantGuardians"
    ADD CONSTRAINT "Nr_ApplicantGuardians_Nr_ApplicantID_fkey" 
    FOREIGN KEY ("Nr_ApplicantID") REFERENCES "Nr_Applicants"("Nr_ApplicantID") ON DELETE CASCADE;

ALTER TABLE "Nr_ApplicantGuardians"
    ADD CONSTRAINT "Nr_ApplicantGuardians_Nr_UserID_fkey" 
    FOREIGN KEY ("Nr_UserID") REFERENCES "Nr_Users"("UserID") ON DELETE RESTRICT;

-- Create indexes
CREATE INDEX IF NOT EXISTS "idx_Nr_ApplicantGuardians_Nr_ApplicantID" ON "Nr_ApplicantGuardians"("Nr_ApplicantID");
CREATE INDEX IF NOT EXISTS "idx_Nr_ApplicantGuardians_Nr_UserID" ON "Nr_ApplicantGuardians"("Nr_UserID");
CREATE INDEX IF NOT EXISTS "idx_Nr_ApplicantGuardians_GUID" ON "Nr_ApplicantGuardians"("GUID");
CREATE UNIQUE INDEX IF NOT EXISTS "uq_Nr_ApplicantGuardians_RegistrationName" ON "Nr_ApplicantGuardians"("RegistrationName")
    WHERE "RegistrationName" IS NOT NULL;

-- Note: Nr_ApplicantGuardianAddress table removed - addresses are now stored in Nr_Addresses table (User module)
-- Note: Nr_ApplicantGuardianContact table removed - contact data (email, phone, mobile, fax) is now in Nr_Users table
-- Note: Phone2 and MobileNumber2 are stored in Nr_ApplicantGuardians table

-- Create Nr_ApplicantGuardianFinance table
CREATE TABLE IF NOT EXISTS "Nr_ApplicantGuardianFinance" (
    "Nr_GuardianFinanceID" INTEGER NOT NULL,
    "Nr_GuardianID" INTEGER,
    "FinancialInstitution" CHARACTER VARYING(255),
    "BankCode" CHARACTER VARYING(255),
    "AccountNumber" CHARACTER VARYING(255),
    "DebtorNumber" CHARACTER VARYING(255),
    "Company" CHARACTER VARYING(255),
    CONSTRAINT "Nr_ApplicantGuardianFinance_pkey" PRIMARY KEY ("Nr_GuardianFinanceID")
);

-- Create sequence for Nr_ApplicantGuardianFinance
CREATE SEQUENCE IF NOT EXISTS "Nr_ApplicantGuardianFinance_Nr_GuardianFinanceID_seq"
    AS INTEGER
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE "Nr_ApplicantGuardianFinance" ALTER COLUMN "Nr_GuardianFinanceID" SET DEFAULT nextval('"Nr_ApplicantGuardianFinance_Nr_GuardianFinanceID_seq"');
ALTER SEQUENCE "Nr_ApplicantGuardianFinance_Nr_GuardianFinanceID_seq" OWNED BY "Nr_ApplicantGuardianFinance"."Nr_GuardianFinanceID";

-- Create foreign key to Nr_ApplicantGuardians
ALTER TABLE "Nr_ApplicantGuardianFinance"
    ADD CONSTRAINT "Nr_ApplicantGuardianFinance_Nr_GuardianID_fkey" 
    FOREIGN KEY ("Nr_GuardianID") REFERENCES "Nr_ApplicantGuardians"("Nr_GuardianID") ON DELETE CASCADE;

-- Create index
CREATE INDEX IF NOT EXISTS "idx_Nr_ApplicantGuardianFinance_Nr_GuardianID" ON "Nr_ApplicantGuardianFinance"("Nr_GuardianID");

-- ============================================================================
-- Phase 3: Create Normalized Tables for Related Applicant Data
-- ============================================================================

-- Create Nr_ApplicantProcedureData table
CREATE TABLE IF NOT EXISTS "Nr_ApplicantProcedureData" (
    "Nr_ProcedureDataID" INTEGER NOT NULL,
    "Nr_ApplicantID" INTEGER,
    "ProcedureNumber" INTEGER,
    "GradeAverage" CHARACTER VARYING(255),
    "DocumentsComplete" SMALLINT,
    "ApplicationRejected" SMALLINT,
    "ApplicationWaitlist" SMALLINT,
    "SelectionAccepted" SMALLINT,
    "CurrentApplicant" SMALLINT,
    "ConfirmationSentOn" TIMESTAMP WITHOUT TIME ZONE,
    "Remark" CHARACTER VARYING(255),
    "GUID" UUID,
    "PortalLastChange" TIMESTAMP WITHOUT TIME ZONE,
    "Withdrawn" SMALLINT DEFAULT 0,
    "ApplicationRegistration" TIMESTAMP WITHOUT TIME ZONE,
    "IsDraft" SMALLINT DEFAULT 0,
    CONSTRAINT "Nr_ApplicantProcedureData_pkey" PRIMARY KEY ("Nr_ProcedureDataID")
);

-- Create sequence for Nr_ApplicantProcedureData
CREATE SEQUENCE IF NOT EXISTS "Nr_ApplicantProcedureData_Nr_ProcedureDataID_seq"
    AS INTEGER
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE "Nr_ApplicantProcedureData" ALTER COLUMN "Nr_ProcedureDataID" SET DEFAULT nextval('"Nr_ApplicantProcedureData_Nr_ProcedureDataID_seq"');
ALTER SEQUENCE "Nr_ApplicantProcedureData_Nr_ProcedureDataID_seq" OWNED BY "Nr_ApplicantProcedureData"."Nr_ProcedureDataID";

-- Create foreign key to Nr_Applicants
ALTER TABLE "Nr_ApplicantProcedureData"
    ADD CONSTRAINT "Nr_ApplicantProcedureData_Nr_ApplicantID_fkey" 
    FOREIGN KEY ("Nr_ApplicantID") REFERENCES "Nr_Applicants"("Nr_ApplicantID") ON DELETE CASCADE;

-- Create indexes
CREATE INDEX IF NOT EXISTS "idx_Nr_ApplicantProcedureData_Nr_ApplicantID" ON "Nr_ApplicantProcedureData"("Nr_ApplicantID");
CREATE INDEX IF NOT EXISTS "idx_Nr_ApplicantProcedureData_ProcedureNumber" ON "Nr_ApplicantProcedureData"("ProcedureNumber");

-- Create Nr_ApplicantDocuments table
CREATE TABLE IF NOT EXISTS "Nr_ApplicantDocuments" (
    "Nr_DocumentID" INTEGER NOT NULL,
    "Nr_ApplicantID" INTEGER,
    "ProcedureNumber" INTEGER,
    "Description" CHARACTER VARYING(255),
    "ProcedureGroup" CHARACTER VARYING(100),
    "GUID" UUID,
    "Timestamp" BYTEA NOT NULL,
    CONSTRAINT "Nr_ApplicantDocuments_pkey" PRIMARY KEY ("Nr_DocumentID")
);

-- Create sequence for Nr_ApplicantDocuments
CREATE SEQUENCE IF NOT EXISTS "Nr_ApplicantDocuments_Nr_DocumentID_seq"
    AS INTEGER
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE "Nr_ApplicantDocuments" ALTER COLUMN "Nr_DocumentID" SET DEFAULT nextval('"Nr_ApplicantDocuments_Nr_DocumentID_seq"');
ALTER SEQUENCE "Nr_ApplicantDocuments_Nr_DocumentID_seq" OWNED BY "Nr_ApplicantDocuments"."Nr_DocumentID";

-- Create foreign key to Nr_Applicants
ALTER TABLE "Nr_ApplicantDocuments"
    ADD CONSTRAINT "Nr_ApplicantDocuments_Nr_ApplicantID_fkey" 
    FOREIGN KEY ("Nr_ApplicantID") REFERENCES "Nr_Applicants"("Nr_ApplicantID") ON DELETE CASCADE;

-- Create indexes
CREATE INDEX IF NOT EXISTS "idx_Nr_ApplicantDocuments_Nr_ApplicantID" ON "Nr_ApplicantDocuments"("Nr_ApplicantID");
CREATE INDEX IF NOT EXISTS "idx_Nr_ApplicantDocuments_ProcedureNumber" ON "Nr_ApplicantDocuments"("ProcedureNumber");

-- Create Nr_ApplicantPerformance table
CREATE TABLE IF NOT EXISTS "Nr_ApplicantPerformance" (
    "Nr_PerformanceID" INTEGER NOT NULL,
    "Nr_ApplicantID" INTEGER,
    "ProcedureNumber" INTEGER,
    "Position" SMALLINT,
    "Subject" CHARACTER VARYING(100),
    "Grade" CHARACTER VARYING(50),
    "GUID" UUID,
    "Tenant" SMALLINT DEFAULT 1 NOT NULL,
    "Timestamp" BYTEA NOT NULL,
    CONSTRAINT "Nr_ApplicantPerformance_pkey" PRIMARY KEY ("Nr_PerformanceID")
);

-- Create sequence for Nr_ApplicantPerformance
CREATE SEQUENCE IF NOT EXISTS "Nr_ApplicantPerformance_Nr_PerformanceID_seq"
    AS INTEGER
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE "Nr_ApplicantPerformance" ALTER COLUMN "Nr_PerformanceID" SET DEFAULT nextval('"Nr_ApplicantPerformance_Nr_PerformanceID_seq"');
ALTER SEQUENCE "Nr_ApplicantPerformance_Nr_PerformanceID_seq" OWNED BY "Nr_ApplicantPerformance"."Nr_PerformanceID";

-- Create foreign key to Nr_Applicants
ALTER TABLE "Nr_ApplicantPerformance"
    ADD CONSTRAINT "Nr_ApplicantPerformance_Nr_ApplicantID_fkey" 
    FOREIGN KEY ("Nr_ApplicantID") REFERENCES "Nr_Applicants"("Nr_ApplicantID") ON DELETE CASCADE;

-- Create indexes
CREATE INDEX IF NOT EXISTS "idx_Nr_ApplicantPerformance_Nr_ApplicantID" ON "Nr_ApplicantPerformance"("Nr_ApplicantID");
CREATE INDEX IF NOT EXISTS "idx_Nr_ApplicantPerformance_ProcedureNumber" ON "Nr_ApplicantPerformance"("ProcedureNumber");

-- ============================================================================
-- Phase 3b: Create Normalized Tables for Procedure Configuration
-- ============================================================================

-- Create Nr_ApplicantProcedure table
CREATE TABLE IF NOT EXISTS "Nr_ApplicantProcedure" (
    "Nr_ProcedureID" INTEGER NOT NULL,
    "From" TIMESTAMP WITHOUT TIME ZONE,
    "To" TIMESTAMP WITHOUT TIME ZONE,
    "Description" CHARACTER VARYING(255),
    "Description_1" TEXT,
    "GUID" UUID,
    "Tenant" SMALLINT DEFAULT 1 NOT NULL,
    "Timestamp" BYTEA NOT NULL,
    "SchoolID" CHARACTER VARYING(255),
    "Status" SMALLINT DEFAULT 1,
    "IsDraft" SMALLINT DEFAULT 0,
    "GradingScale" CHARACTER VARYING(255),
    "AgeLimit" INTEGER,
    CONSTRAINT "Nr_ApplicantProcedure_pkey" PRIMARY KEY ("Nr_ProcedureID")
);

-- Create sequence for Nr_ApplicantProcedure
CREATE SEQUENCE IF NOT EXISTS "Nr_ApplicantProcedure_Nr_ProcedureID_seq"
    AS INTEGER
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE "Nr_ApplicantProcedure" ALTER COLUMN "Nr_ProcedureID" SET DEFAULT nextval('"Nr_ApplicantProcedure_Nr_ProcedureID_seq"');
ALTER SEQUENCE "Nr_ApplicantProcedure_Nr_ProcedureID_seq" OWNED BY "Nr_ApplicantProcedure"."Nr_ProcedureID";

-- Update sequence to start from max ID after migration (will be set after data migration)

-- Create indexes
CREATE INDEX IF NOT EXISTS "idx_Nr_ApplicantProcedure_GUID" ON "Nr_ApplicantProcedure"("GUID");
CREATE INDEX IF NOT EXISTS "idx_Nr_ApplicantProcedure_SchoolID" ON "Nr_ApplicantProcedure"("SchoolID");

-- Create Nr_ApplicantProcedureDocuments table
CREATE TABLE IF NOT EXISTS "Nr_ApplicantProcedureDocuments" (
    "Nr_ProcedureDocumentID" INTEGER NOT NULL,
    "ProcedureNumber" INTEGER,
    "ProcedureGroup" CHARACTER VARYING(100),
    "Mandatory" SMALLINT,
    "Tenant" SMALLINT DEFAULT 1 NOT NULL,
    CONSTRAINT "Nr_ApplicantProcedureDocuments_pkey" PRIMARY KEY ("Nr_ProcedureDocumentID")
);

-- Create sequence for Nr_ApplicantProcedureDocuments
CREATE SEQUENCE IF NOT EXISTS "Nr_ApplicantProcedureDocuments_Nr_ProcedureDocumentID_seq"
    AS INTEGER
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE "Nr_ApplicantProcedureDocuments" ALTER COLUMN "Nr_ProcedureDocumentID" SET DEFAULT nextval('"Nr_ApplicantProcedureDocuments_Nr_ProcedureDocumentID_seq"');
ALTER SEQUENCE "Nr_ApplicantProcedureDocuments_Nr_ProcedureDocumentID_seq" OWNED BY "Nr_ApplicantProcedureDocuments"."Nr_ProcedureDocumentID";

-- Create foreign key to Nr_ApplicantProcedure
ALTER TABLE "Nr_ApplicantProcedureDocuments"
    ADD CONSTRAINT "Nr_ApplicantProcedureDocuments_ProcedureNumber_fkey" 
    FOREIGN KEY ("ProcedureNumber") REFERENCES "Nr_ApplicantProcedure"("Nr_ProcedureID") ON DELETE CASCADE;

-- Create indexes
CREATE INDEX IF NOT EXISTS "idx_Nr_ApplicantProcedureDocuments_ProcedureNumber" ON "Nr_ApplicantProcedureDocuments"("ProcedureNumber");

-- Create Nr_ApplicantProcedureFieldsConfig table
CREATE TABLE IF NOT EXISTS "Nr_ApplicantProcedureFieldsConfig" (
    "Nr_FieldsConfigID" INTEGER NOT NULL,
    "ApplicantProcedureNumber" INTEGER NOT NULL,
    "FieldName" CHARACTER VARYING(255) NOT NULL,
    "DisplayName" CHARACTER VARYING(255) NOT NULL,
    "ConstraintValue" SMALLINT,
    "Required" SMALLINT NOT NULL,
    "DefaultValue" CHARACTER VARYING(255),
    "Category" CHARACTER VARYING(255),
    "Tenant" SMALLINT DEFAULT 1 NOT NULL,
    "TableNumber" INTEGER,
    "Position" SMALLINT,
    CONSTRAINT "Nr_ApplicantProcedureFieldsConfig_pkey" PRIMARY KEY ("Nr_FieldsConfigID")
);

-- Create sequence for Nr_ApplicantProcedureFieldsConfig
CREATE SEQUENCE IF NOT EXISTS "Nr_ApplicantProcedureFieldsConfig_Nr_FieldsConfigID_seq"
    AS INTEGER
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE "Nr_ApplicantProcedureFieldsConfig" ALTER COLUMN "Nr_FieldsConfigID" SET DEFAULT nextval('"Nr_ApplicantProcedureFieldsConfig_Nr_FieldsConfigID_seq"');
ALTER SEQUENCE "Nr_ApplicantProcedureFieldsConfig_Nr_FieldsConfigID_seq" OWNED BY "Nr_ApplicantProcedureFieldsConfig"."Nr_FieldsConfigID";

-- Create foreign key to Nr_ApplicantProcedure
ALTER TABLE "Nr_ApplicantProcedureFieldsConfig"
    ADD CONSTRAINT "Nr_ApplicantProcedureFieldsConfig_ApplicantProcedureNumber_fkey" 
    FOREIGN KEY ("ApplicantProcedureNumber") REFERENCES "Nr_ApplicantProcedure"("Nr_ProcedureID") ON DELETE CASCADE;

-- Create indexes
CREATE INDEX IF NOT EXISTS "idx_Nr_ApplicantProcedureFieldsConfig_ProcedureNumber" ON "Nr_ApplicantProcedureFieldsConfig"("ApplicantProcedureNumber");

-- Create Nr_ApplicantProcedureSubjects table
CREATE TABLE IF NOT EXISTS "Nr_ApplicantProcedureSubjects" (
    "Nr_ProcedureSubjectID" INTEGER NOT NULL,
    "ProcedureNumber" INTEGER NOT NULL,
    "SubjectNumber" INTEGER NOT NULL,
    "Tenant" SMALLINT DEFAULT 1 NOT NULL,
    CONSTRAINT "Nr_ApplicantProcedureSubjects_pkey" PRIMARY KEY ("Nr_ProcedureSubjectID")
);

-- Create sequence for Nr_ApplicantProcedureSubjects
CREATE SEQUENCE IF NOT EXISTS "Nr_ApplicantProcedureSubjects_Nr_ProcedureSubjectID_seq"
    AS INTEGER
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE "Nr_ApplicantProcedureSubjects" ALTER COLUMN "Nr_ProcedureSubjectID" SET DEFAULT nextval('"Nr_ApplicantProcedureSubjects_Nr_ProcedureSubjectID_seq"');
ALTER SEQUENCE "Nr_ApplicantProcedureSubjects_Nr_ProcedureSubjectID_seq" OWNED BY "Nr_ApplicantProcedureSubjects"."Nr_ProcedureSubjectID";

-- Create foreign key to Nr_ApplicantProcedure
ALTER TABLE "Nr_ApplicantProcedureSubjects"
    ADD CONSTRAINT "Nr_ApplicantProcedureSubjects_ProcedureNumber_fkey" 
    FOREIGN KEY ("ProcedureNumber") REFERENCES "Nr_ApplicantProcedure"("Nr_ProcedureID") ON DELETE CASCADE;

-- Create indexes
CREATE INDEX IF NOT EXISTS "idx_Nr_ApplicantProcedureSubjects_ProcedureNumber" ON "Nr_ApplicantProcedureSubjects"("ProcedureNumber");

-- ============================================================================
-- Phase 4: Migrate Data from Old Tables to Normalized Tables
-- ============================================================================

-- Step 0: Handle legacy applicants without UserID
-- Create Users and Addresses for applicants that don't have them yet
-- Deduplication Logic:
-- 1. If Email exists: Deduplicate by Email (merges multiple apps from same email)
-- 2. If Email is NULL: Deduplicate by FirstName + Name (creates unique user for each name)
WITH UniqueApplicants AS (
    SELECT DISTINCT ON (
        CASE 
            WHEN "Email" IS NOT NULL AND "Email" <> '' THEN "Email" 
            ELSE "FirstName" || "Name" 
        END
    )
        "FirstName",
        "Name",
        "Email",
        "Street",
        "PostalCode",
        "Residence" as "City",
        "Country",
        "GUID" as "RepresentativeGUID" -- Pick one GUID to represent the user (for address data source)
    FROM "ApplicantTable"
    WHERE "UserID" IS NULL
),
NewUserIDs AS (
    SELECT 
        "FirstName",
        "Name",
        "Email",
        "RepresentativeGUID",
        nextval('"Nr_Addresses_ID_seq"') as NewAddressID,
        nextval('"Nr_Users_UserID_seq"') as NewUserID
    FROM UniqueApplicants
),
InsertAddresses AS (
    INSERT INTO "Nr_Addresses" (
        "ID", "Street", "PostalCode", "City", "Country", 
        "AddressType", "Tenant", "CreatedAt", "UpdatedAt"
    )
    SELECT
        n.NewAddressID,
        COALESCE(ua."Street", ''),
        COALESCE(ua."PostalCode", ''),
        COALESCE(ua."City", ''),
        COALESCE(ua."Country", 'DE'),
        'APPLICANT',
        1,
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP
    FROM NewUserIDs n
    JOIN UniqueApplicants ua ON 
        (
            -- Match by Email if present
            COALESCE(ua."Email", '') <> '' 
            AND ua."Email" = n."Email"
        )
        OR
        (
            -- Match by Name if Email is missing
            COALESCE(ua."Email", '') = '' 
            AND COALESCE(n."Email", '') = ''
            AND COALESCE(ua."FirstName", '') = COALESCE(n."FirstName", '')
            AND COALESCE(ua."Name", '') = COALESCE(n."Name", '')
        )
),
InsertUsers AS (
    INSERT INTO "Nr_Users" (
        "UserID", "Nr_AddressID", "FirstName", "LastName", "Email",
        "GlobalUID", "TenantID", "LastModified"
    )
    SELECT
        n.NewUserID,
        n.NewAddressID,
        COALESCE(n."FirstName", ''),
        COALESCE(n."Name", ''),
        n."Email",
        n."RepresentativeGUID", 
        1,
        CURRENT_TIMESTAMP
    FROM NewUserIDs n
)
UPDATE "ApplicantTable" at
SET "UserID" = n.NewUserID
FROM NewUserIDs n
WHERE 
    at."UserID" IS NULL
    AND (
        (
            -- Match by Email if present
            COALESCE(at."Email", '') <> '' 
            AND at."Email" = n."Email"
        )
        OR
        (
            -- Match by Name if Email is missing
            COALESCE(at."Email", '') = '' 
            AND COALESCE(n."Email", '') = ''
            AND COALESCE(at."FirstName", '') = COALESCE(n."FirstName", '')
            AND COALESCE(at."Name", '') = COALESCE(n."Name", '')
        )
    );

-- IMPORTANT: Step 1 assumes all applicants have a valid UserID.
-- For standard applicants, this links to the existing UserID from the old Users table.
-- For legacy applicants (originally without UserID), Step 0 has already created the User records and backfilled the ID.
-- Therefore, at this stage, we simply link to the existing (or newly created) UserID.

-- Step 1: Migrate to Nr_Applicants (linking to existing User records via UserID)
-- Each applicant record represents one application by a user to a procedure
-- One user can have MULTIPLE applicant records (one per procedure they apply to)
INSERT INTO "Nr_Applicants" (
    "Nr_UserID",
    "Disability",
    "MotherTongue",
    "GUID",
    "Timestamp"
)
SELECT
    at."UserID" AS "Nr_UserID",  -- Use the existing UserID from ApplicantTable!
    COALESCE(at."Disability", 0) AS "Disability",
    at."MotherTongue",
    at."GUID",
    at."Timestamp"
FROM "ApplicantTable" at
WHERE at."UserID" IS NOT NULL  -- Only migrate records with valid UserID
AND EXISTS (
    SELECT 1 FROM "Nr_Users" u WHERE u."UserID" = at."UserID"  -- Ensure user exists
)
AND NOT EXISTS (
    SELECT 1 FROM "Nr_Applicants" na
    WHERE na."Nr_UserID" = at."UserID"
    AND na."GUID" = at."GUID"  -- Use GUID to identify unique applicant records
);

-- Note: Step 2 - Address migration removed - addresses are now stored in Nr_Addresses table (User module)
-- Step 3: Contact data (email, phone, mobile, fax) is already in Nr_Users table
-- Note: Nr_ApplicantContact table removed - contact data is now in Nr_Users table

-- Step 4: Migrate application-specific data to Nr_ApplicantApplicationInfo
INSERT INTO "Nr_ApplicantApplicationInfo" (
    "Nr_ApplicantID",
    "Class",
    "TrainingCompany",
    "FormSuffix",
    "GuestStudent",
    "AdmissionDate",
    "CompanyLock"
)
SELECT
    na."Nr_ApplicantID",
    at."Class",
    at."TrainingCompany",
    at."FormSuffix",
    COALESCE(at."GuestStudent", 0) AS "GuestStudent",
    at."AdmissionDate",
    COALESCE(at."CompanyLock", 0) AS "CompanyLock"
FROM "ApplicantTable" at
INNER JOIN "Nr_Applicants" na ON (
    na."Nr_UserID" = at."UserID"
    AND na."GUID" = at."GUID"  -- Match exact applicant record
)
WHERE (
    at."Class" IS NOT NULL
    OR at."TrainingCompany" IS NOT NULL
    OR at."FormSuffix" IS NOT NULL
    OR at."GuestStudent" IS NOT NULL
    OR at."AdmissionDate" IS NOT NULL
    OR at."CompanyLock" IS NOT NULL
)
AND NOT EXISTS (
    SELECT 1 FROM "Nr_ApplicantApplicationInfo" naai WHERE naai."Nr_ApplicantID" = na."Nr_ApplicantID"
);

-- Step 6: Create or link User records for guardians (if guardian has account)
-- Note: Adjust logic based on your guardian User account strategy
INSERT INTO "Nr_Users" (
    "FirstName",
    "LastName",
    "BirthName",
    "NameAddition",
    "BirthDate",
    "BirthPlace",
    "Gender",
    "Email",
    "Phone",
    "Mobile",
    "Fax",
    "SchoolID",
    "TenantID",
    "LastModified"
)
SELECT DISTINCT ON (agt."ID")
    agt."FirstName",
    agt."Name" AS "LastName",
    NULL AS "BirthName", -- Not in ApplicantGuardianTable
    agt."Addition" AS "NameAddition",
    NULL AS "BirthDate", -- Not in ApplicantGuardianTable
    NULL AS "BirthPlace", -- Not in ApplicantGuardianTable
    NULL AS "Gender", -- Not in ApplicantGuardianTable
    agt."Email",
    agt."Phone",
    agt."MobileNumber" AS "Mobile",
    agt."Fax",
    agt."SchoolID",
    COALESCE(agt."Tenant", 1) AS "TenantID",
    CURRENT_TIMESTAMP AS "LastModified"
FROM "ApplicantGuardianTable" agt
WHERE agt."Name" IS NOT NULL 
AND agt."FirstName" IS NOT NULL
AND NOT EXISTS (
    SELECT 1 FROM "Nr_Users" u 
    WHERE u."FirstName" = agt."FirstName" 
    AND u."LastName" = agt."Name"
    AND u."Email" = agt."Email"
)
ON CONFLICT DO NOTHING;

-- Step 7: Migrate to Nr_ApplicantGuardians (guardians MUST have User accounts - Nr_UserID is NOT NULL)
-- Note: Portal registration data (RegistrationX, RegistrationName) is now migrated directly here
INSERT INTO "Nr_ApplicantGuardians" (
    "Nr_ApplicantID",
    "Nr_UserID",
    "StudentNumber",
    "Category",
    "Priority",
    "Salutation",
    "LetterSalutation",
    "Title",
    "Addition",
    "Profession",
    "Denomination",
    "CountryOfBirth",
    "GuardianshipAuthorized",
    "CustodyAuthorized",
    "SameHousehold",
    "CompanyCarrier",
    "FamilyCode",
    "Remark",
    "Phone2",
    "MobileNumber2",
    "GUID",
    "XmoodID",
    "GlobalUID",
    "RegistrationX",
    "RegistrationName",
    "Timestamp"
)
SELECT 
    na."Nr_ApplicantID",
    u."UserID" AS "Nr_UserID", -- Required - guardian must have User account
    agt."StudentNumber",
    agt."Category",
    agt."Priority",
    agt."Salutation",
    agt."LetterSalutation",
    agt."Title",
    agt."Addition",
    agt."Profession",
    agt."Denomination",
    agt."CountryOfBirth",
    COALESCE(agt."GuardianshipAuthorized", 0) AS "GuardianshipAuthorized",
    COALESCE(agt."CustodyAuthorized", 0) AS "CustodyAuthorized",
    COALESCE(agt."SameHousehold", 0) AS "SameHousehold",
    COALESCE(agt."CompanyCarrier", 0) AS "CompanyCarrier",
    agt."FamilyCode",
    agt."Remark",
    agt."Phone2",
    agt."MobileNumber2",
    agt."XmoodID" AS "GUID", -- Using XmoodID as GUID if GUID not available
    agt."XmoodID",
    agt."GlobalUID",
    agt."RegistrationX",  -- Portal registration data now directly in Nr_ApplicantGuardians
    agt."RegistrationName",  -- Portal registration data now directly in Nr_ApplicantGuardians
    agt."Timestamp"
FROM "ApplicantGuardianTable" agt
INNER JOIN "ApplicantTable" at ON at."ID" = agt."StudentNumber" -- StudentNumber maps to ApplicantTable.ID
INNER JOIN "Nr_Applicants" na ON (
    na."Nr_UserID" = at."UserID"
    AND na."GUID" = at."GUID"  -- Match exact applicant record
)
INNER JOIN "Nr_Users" u ON (
    u."FirstName" = agt."FirstName"
    AND u."LastName" = agt."Name"
    AND u."Email" = agt."Email"
)
WHERE u."UserID" IS NOT NULL
AND NOT EXISTS (
    SELECT 1 FROM "Nr_ApplicantGuardians" nag
    WHERE nag."Nr_ApplicantID" = na."Nr_ApplicantID"
    AND nag."StudentNumber" = agt."StudentNumber"
);

-- Note: Step 8 - Guardian address migration removed - addresses are now stored in Nr_Addresses table (User module)
-- Step 9: Guardian contact data (email, phone, mobile, fax) is migrated to Nr_Users table in Step 6
-- Phone2 and MobileNumber2 are migrated to Nr_ApplicantGuardians table in Step 7
-- Note: Nr_ApplicantGuardianContact table removed - contact data is now in Nr_Users table

-- Step 10: Migrate guardian financial data to Nr_ApplicantGuardianFinance
INSERT INTO "Nr_ApplicantGuardianFinance" (
    "Nr_GuardianID",
    "FinancialInstitution",
    "BankCode",
    "AccountNumber",
    "DebtorNumber",
    "Company"
)
SELECT 
    nag."Nr_GuardianID",
    agt."FinancialInstitution",
    agt."BankCode",
    agt."AccountNumber",
    agt."DebtorNumber",
    agt."Company"
FROM "ApplicantGuardianTable" agt
INNER JOIN "ApplicantTable" at ON at."ID" = agt."StudentNumber"
INNER JOIN "Nr_Applicants" na ON (
    na."Nr_UserID" = at."UserID"
    AND na."GUID" = at."GUID"  -- Match exact applicant record
)
INNER JOIN "Nr_ApplicantGuardians" nag ON (
    nag."Nr_ApplicantID" = na."Nr_ApplicantID"
    AND nag."StudentNumber" = agt."StudentNumber"
)
WHERE (
    agt."FinancialInstitution" IS NOT NULL
    OR agt."BankCode" IS NOT NULL
    OR agt."AccountNumber" IS NOT NULL
    OR agt."DebtorNumber" IS NOT NULL
    OR agt."Company" IS NOT NULL
)
AND NOT EXISTS (
    SELECT 1 FROM "Nr_ApplicantGuardianFinance" nagf WHERE nagf."Nr_GuardianID" = nag."Nr_GuardianID"
);

-- Note: Step 11 - Portal data migration removed - portal data is now migrated directly in Step 7

-- ============================================================================
-- Phase 5: Migrate Procedure Configuration Data to Normalized Tables
-- ============================================================================
-- IMPORTANT: Procedure configuration must be migrated BEFORE related data tables

-- Migrate ApplicantProcedure to Nr_ApplicantProcedure
-- IMPORTANT: Preserve the original ID to maintain foreign key relationships
INSERT INTO "Nr_ApplicantProcedure" (
    "Nr_ProcedureID",
    "From",
    "To",
    "Description",
    "Description_1",
    "GUID",
    "Tenant",
    "Timestamp",
    "SchoolID",
    "Status",
    "IsDraft",
    "GradingScale",
    "AgeLimit"
)
SELECT 
    ap."ID" AS "Nr_ProcedureID",  -- Preserve original ID to maintain foreign key relationships
    ap."From",
    ap."To",
    ap."Description",
    ap."Description_1",
    ap."GUID",
    COALESCE(ap."Tenant", 1) AS "Tenant",
    ap."Timestamp",
    ap."SchoolID",
    COALESCE(ap."Status", 1) AS "Status",
    COALESCE(ap."IsDraft", 0) AS "IsDraft",
    ap."GradingScale",
    ap."AgeLimit"
FROM "ApplicantProcedure" ap
WHERE NOT EXISTS (
    SELECT 1 FROM "Nr_ApplicantProcedure" nap 
    WHERE nap."Nr_ProcedureID" = ap."ID"
    OR nap."GUID" = ap."GUID"
    OR (nap."From" = ap."From" AND nap."To" = ap."To" AND nap."Description" = ap."Description")
);

-- Update sequence to start from max ID to avoid conflicts with preserved IDs
SELECT setval('"Nr_ApplicantProcedure_Nr_ProcedureID_seq"',
    COALESCE((SELECT MAX("Nr_ProcedureID") FROM "Nr_ApplicantProcedure"), 1),
    true);

-- ============================================================================
-- Phase 6: Migrate Data from Related Tables to Normalized Tables
-- ============================================================================
-- IMPORTANT: These migrations must happen AFTER Nr_ApplicantProcedure is populated (Phase 5)
-- Uses DISTINCT ON to handle duplicate users/applicants created by earlier migrations

-- Migrate ApplicantProcedureData to Nr_ApplicantProcedureData
-- IMPORTANT: This migration happens AFTER Nr_ApplicantProcedure is populated
-- Links via ApplicantTable.UserID and GUID to find the exact Nr_Applicants record
-- Only migrate records where the procedure exists in Nr_ApplicantProcedure
INSERT INTO "Nr_ApplicantProcedureData" (
    "Nr_ApplicantID",
    "ProcedureNumber",
    "GradeAverage",
    "DocumentsComplete",
    "ApplicationRejected",
    "ApplicationWaitlist",
    "SelectionAccepted",
    "CurrentApplicant",
    "ConfirmationSentOn",
    "Remark",
    "GUID",
    "PortalLastChange",
    "Withdrawn",
    "ApplicationRegistration",
    "IsDraft"
)
SELECT
    na."Nr_ApplicantID",
    apd."ProcedureNumber",
    apd."GradeAverage",
    apd."DocumentsComplete",
    apd."ApplicationRejected",
    apd."ApplicationWaitlist",
    apd."SelectionAccepted",
    apd."CurrentApplicant",
    apd."ConfirmationSentOn",
    apd."Remark",
    apd."GUID",
    apd."PortalLastChange",
    COALESCE(apd."Withdrawn", 0),
    apd."ApplicationRegistration",
    COALESCE(apd."IsDraft", 0)
FROM "ApplicantProcedureData" apd
INNER JOIN "ApplicantTable" at ON at."ID" = apd."ApplicantNumber"
INNER JOIN "Nr_Applicants" na ON (
    na."Nr_UserID" = at."UserID"
    AND na."GUID" = at."GUID"  -- Match exact applicant record
)
INNER JOIN "Nr_ApplicantProcedure" nap ON nap."Nr_ProcedureID" = apd."ProcedureNumber"
WHERE NOT EXISTS (
    SELECT 1 FROM "Nr_ApplicantProcedureData" existing
    WHERE existing."Nr_ApplicantID" = na."Nr_ApplicantID"
    AND existing."ProcedureNumber" = apd."ProcedureNumber"
);

-- Migrate ApplicantDocuments to Nr_ApplicantDocuments
-- Links via ApplicantTable.UserID and GUID to find the exact Nr_Applicants record
INSERT INTO "Nr_ApplicantDocuments" (
    "Nr_ApplicantID",
    "ProcedureNumber",
    "Description",
    "ProcedureGroup",
    "GUID",
    "Timestamp"
)
SELECT
    na."Nr_ApplicantID",
    ad."ProcedureNumber",
    ad."Description",
    ad."ProcedureGroup",
    ad."GUID",
    ad."Timestamp"
FROM "ApplicantDocuments" ad
INNER JOIN "ApplicantTable" at ON at."ID" = ad."ApplicantNumber"
INNER JOIN "Nr_Applicants" na ON (
    na."Nr_UserID" = at."UserID"
    AND na."GUID" = at."GUID"  -- Match exact applicant record
)
INNER JOIN "Nr_ApplicantProcedure" nap ON nap."Nr_ProcedureID" = ad."ProcedureNumber"
WHERE NOT EXISTS (
    SELECT 1 FROM "Nr_ApplicantDocuments" nad
    WHERE nad."Nr_ApplicantID" = na."Nr_ApplicantID"
    AND nad."ProcedureNumber" = ad."ProcedureNumber"
    AND nad."Description" = ad."Description"
);

-- Migrate ApplicantPerformance to Nr_ApplicantPerformance
-- Links via ApplicantTable.UserID and GUID to find the exact Nr_Applicants record
INSERT INTO "Nr_ApplicantPerformance" (
    "Nr_ApplicantID",
    "ProcedureNumber",
    "Position",
    "Subject",
    "Grade",
    "GUID",
    "Tenant",
    "Timestamp"
)
SELECT
    na."Nr_ApplicantID",
    ap."ProcedureNumber",
    ap."Position",
    ap."Subject",
    ap."Grade",
    ap."GUID",
    COALESCE(ap."Tenant", 1) AS "Tenant",
    ap."Timestamp"
FROM "ApplicantPerformance" ap
INNER JOIN "ApplicantTable" at ON at."ID" = ap."ApplicantNumber"
INNER JOIN "Nr_Applicants" na ON (
    na."Nr_UserID" = at."UserID"
    AND na."GUID" = at."GUID"  -- Match exact applicant record
)
INNER JOIN "Nr_ApplicantProcedure" nap ON nap."Nr_ProcedureID" = ap."ProcedureNumber"
WHERE NOT EXISTS (
    SELECT 1 FROM "Nr_ApplicantPerformance" nap_perf
    WHERE nap_perf."Nr_ApplicantID" = na."Nr_ApplicantID"
    AND nap_perf."ProcedureNumber" = ap."ProcedureNumber"
    AND nap_perf."Subject" = ap."Subject"
);

-- ============================================================================
-- Phase 7: Migrate Procedure Configuration Detail Tables
-- ============================================================================

-- Migrate ApplicantProcedureDocuments to Nr_ApplicantProcedureDocuments
-- Note: Since we preserved the original ID, we can use it directly
INSERT INTO "Nr_ApplicantProcedureDocuments" (
    "ProcedureNumber",
    "ProcedureGroup",
    "Mandatory",
    "Tenant"
)
SELECT 
    apd."ProcedureNumber",  -- Already matches Nr_ProcedureID since we preserved the ID
    apd."ProcedureGroup",
    apd."Mandatory",
    COALESCE(apd."Tenant", 1) AS "Tenant"
FROM "ApplicantProcedureDocuments" apd
INNER JOIN "Nr_ApplicantProcedure" nap ON nap."Nr_ProcedureID" = apd."ProcedureNumber"
WHERE NOT EXISTS (
    SELECT 1 FROM "Nr_ApplicantProcedureDocuments" napd 
    WHERE napd."ProcedureNumber" = apd."ProcedureNumber"
    AND napd."ProcedureGroup" = apd."ProcedureGroup"
);

-- Migrate ApplicantProcedureFieldsConfig to Nr_ApplicantProcedureFieldsConfig
-- Note: Since we preserved the original ID, we can use it directly
INSERT INTO "Nr_ApplicantProcedureFieldsConfig" (
    "ApplicantProcedureNumber",
    "FieldName",
    "DisplayName",
    "ConstraintValue",
    "Required",
    "DefaultValue",
    "Category",
    "Tenant",
    "TableNumber",
    "Position"
)
SELECT 
    apfc."ApplicantProcedureNumber",  -- Already matches Nr_ProcedureID since we preserved the ID
    apfc."FieldName",
    apfc."DisplayName",
    apfc."ConstraintValue",
    apfc."Required",
    apfc."DefaultValue",
    apfc."Category",
    COALESCE(apfc."Tenant", 1) AS "Tenant",
    apfc."TableNumber",
    apfc."Position"
FROM "ApplicantProcedureFieldsConfig" apfc
INNER JOIN "Nr_ApplicantProcedure" nap ON nap."Nr_ProcedureID" = apfc."ApplicantProcedureNumber"
WHERE NOT EXISTS (
    SELECT 1 FROM "Nr_ApplicantProcedureFieldsConfig" napfc 
    WHERE napfc."ApplicantProcedureNumber" = apfc."ApplicantProcedureNumber"
    AND napfc."FieldName" = apfc."FieldName"
);

-- Migrate ApplicantProcedureSubjects to Nr_ApplicantProcedureSubjects
-- Note: Since we preserved the original ID, we can use it directly
INSERT INTO "Nr_ApplicantProcedureSubjects" (
    "ProcedureNumber",
    "SubjectNumber",
    "Tenant"
)
SELECT 
    aps."ProcedureNumber",  -- Already matches Nr_ProcedureID since we preserved the ID
    aps."SubjectNumber",
    COALESCE(aps."Tenant", 1) AS "Tenant"
FROM "ApplicantProcedureSubjects" aps
INNER JOIN "Nr_ApplicantProcedure" nap ON nap."Nr_ProcedureID" = aps."ProcedureNumber"
WHERE NOT EXISTS (
    SELECT 1 FROM "Nr_ApplicantProcedureSubjects" naps 
    WHERE naps."ProcedureNumber" = aps."ProcedureNumber"
    AND naps."SubjectNumber" = aps."SubjectNumber"
);

-- Update foreign key references in Nr_ApplicantProcedureData, Nr_ApplicantDocuments, Nr_ApplicantPerformance
-- Since we preserved the original ID in Nr_ApplicantProcedure.Nr_ProcedureID, the ProcedureNumber values
-- should already match. However, we'll verify and update any that don't match.

-- Update Nr_ApplicantProcedureData.ProcedureNumber to reference Nr_ApplicantProcedure.Nr_ProcedureID
-- (This should be a no-op if IDs were preserved, but ensures consistency)
UPDATE "Nr_ApplicantProcedureData" napd
SET "ProcedureNumber" = nap."Nr_ProcedureID"
FROM "ApplicantProcedure" ap
INNER JOIN "Nr_ApplicantProcedure" nap ON nap."Nr_ProcedureID" = ap."ID"
WHERE napd."ProcedureNumber" = ap."ID"
AND napd."ProcedureNumber" != nap."Nr_ProcedureID";

-- Update Nr_ApplicantDocuments.ProcedureNumber to reference Nr_ApplicantProcedure.Nr_ProcedureID
UPDATE "Nr_ApplicantDocuments" nad
SET "ProcedureNumber" = nap."Nr_ProcedureID"
FROM "ApplicantProcedure" ap
INNER JOIN "Nr_ApplicantProcedure" nap ON nap."Nr_ProcedureID" = ap."ID"
WHERE nad."ProcedureNumber" = ap."ID"
AND nad."ProcedureNumber" != nap."Nr_ProcedureID";

-- Update Nr_ApplicantPerformance.ProcedureNumber to reference Nr_ApplicantProcedure.Nr_ProcedureID
UPDATE "Nr_ApplicantPerformance" nap
SET "ProcedureNumber" = nap_proc."Nr_ProcedureID"
FROM "ApplicantProcedure" ap
INNER JOIN "Nr_ApplicantProcedure" nap_proc ON nap_proc."Nr_ProcedureID" = ap."ID"
WHERE nap."ProcedureNumber" = ap."ID"
AND nap."ProcedureNumber" != nap_proc."Nr_ProcedureID";

-- Add foreign key constraints for ProcedureNumber references
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'Nr_ApplicantProcedureData_ProcedureNumber_fkey'
    ) THEN
        ALTER TABLE "Nr_ApplicantProcedureData"
            ADD CONSTRAINT "Nr_ApplicantProcedureData_ProcedureNumber_fkey"
            FOREIGN KEY ("ProcedureNumber") REFERENCES "Nr_ApplicantProcedure"("Nr_ProcedureID") ON DELETE CASCADE;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'Nr_ApplicantDocuments_ProcedureNumber_fkey'
    ) THEN
        ALTER TABLE "Nr_ApplicantDocuments"
            ADD CONSTRAINT "Nr_ApplicantDocuments_ProcedureNumber_fkey"
            FOREIGN KEY ("ProcedureNumber") REFERENCES "Nr_ApplicantProcedure"("Nr_ProcedureID") ON DELETE CASCADE;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'Nr_ApplicantPerformance_ProcedureNumber_fkey'
    ) THEN
        ALTER TABLE "Nr_ApplicantPerformance"
            ADD CONSTRAINT "Nr_ApplicantPerformance_ProcedureNumber_fkey"
            FOREIGN KEY ("ProcedureNumber") REFERENCES "Nr_ApplicantProcedure"("Nr_ProcedureID") ON DELETE CASCADE;
    END IF;
END $$;

-- Note: Flyway automatically commits the transaction

-- ============================================================================
-- Post-Migration Validation Queries
-- ============================================================================

-- Uncomment and run these queries to validate the migration:

-- Applicant migration validation
-- SELECT COUNT(*) AS total_applicants FROM "ApplicantTable";
-- SELECT COUNT(*) AS migrated_applicants FROM "Nr_Applicants";
-- Note: Nr_UserID is NOT NULL - all applicants must have User accounts
-- SELECT COUNT(*) FROM "Nr_Applicants" WHERE "Nr_UserID" IS NULL; -- Should always return 0

-- Guardian migration validation
-- SELECT COUNT(*) AS total_guardians FROM "ApplicantGuardianTable";
-- SELECT COUNT(*) AS migrated_guardians FROM "Nr_ApplicantGuardians";
-- Note: Nr_UserID is NOT NULL - all guardians must have User accounts
-- SELECT COUNT(*) FROM "Nr_ApplicantGuardians" WHERE "Nr_UserID" IS NULL; -- Should always return 0

-- Related tables migration validation
-- SELECT COUNT(*) AS total_procedure_data FROM "ApplicantProcedureData";
-- SELECT COUNT(*) AS migrated_procedure_data FROM "Nr_ApplicantProcedureData";
-- SELECT COUNT(*) AS total_documents FROM "ApplicantDocuments";
-- SELECT COUNT(*) AS migrated_documents FROM "Nr_ApplicantDocuments";
-- SELECT COUNT(*) AS total_performance FROM "ApplicantPerformance";
-- SELECT COUNT(*) AS migrated_performance FROM "Nr_ApplicantPerformance";

-- Procedure configuration tables migration validation
-- SELECT COUNT(*) AS total_procedures FROM "ApplicantProcedure";
-- SELECT COUNT(*) AS migrated_procedures FROM "Nr_ApplicantProcedure";
-- SELECT COUNT(*) AS total_procedure_documents FROM "ApplicantProcedureDocuments";
-- SELECT COUNT(*) AS migrated_procedure_documents FROM "Nr_ApplicantProcedureDocuments";
-- SELECT COUNT(*) AS total_fields_config FROM "ApplicantProcedureFieldsConfig";
-- SELECT COUNT(*) AS migrated_fields_config FROM "Nr_ApplicantProcedureFieldsConfig";
-- SELECT COUNT(*) AS total_procedure_subjects FROM "ApplicantProcedureSubjects";
-- SELECT COUNT(*) AS migrated_procedure_subjects FROM "Nr_ApplicantProcedureSubjects";

-- Data integrity check
-- SELECT na."Nr_ApplicantID", u."FirstName", u."LastName"
-- FROM "Nr_Applicants" na
-- INNER JOIN "Nr_Users" u ON na."Nr_UserID" = u."UserID"
-- LIMIT 10;

