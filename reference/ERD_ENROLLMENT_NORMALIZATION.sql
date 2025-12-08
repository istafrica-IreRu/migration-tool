-- =============================================================================
-- SQL DDL for IST-WinSchool Enrollment Module Normalized Tables - ERD Generation
-- =============================================================================
-- Generate ERD at: https://www.eraser.io/ai/erd-generator
-- Paste this entire SQL script into the generator
--
-- Project: IST-WinSchool
-- Module: Enrollment
-- Database: PostgreSQL
-- Normalization: 3rd Normal Form (3NF)
-- =============================================================================

-- =============================================================================
-- SECTION 1: USER TABLE (Shared with Student Module)
-- =============================================================================

CREATE TABLE "Nr_Users" (
    "UserID" SERIAL PRIMARY KEY,
    "LoginName" VARCHAR(20) UNIQUE,
    "PasswordHash" VARCHAR(255),
    "FirstName" VARCHAR(35),
    "LastName" VARCHAR(40),
    "Comment" VARCHAR(255),
    "TenantID" SMALLINT NOT NULL,
    "IsTenantAdmin" BOOLEAN DEFAULT FALSE,
    "SchoolID" VARCHAR(10),
    "GroupID" INTEGER,
    "SystemID" VARCHAR(200),
    "IDNumber" INTEGER,
    "LastModified" TIMESTAMP,
    "KeycloakId" VARCHAR(255),
    "Email" VARCHAR(150),
    "Phone" VARCHAR(25),
    "Mobile" VARCHAR(25),
    "Gender" SMALLINT,
    "BirthDate" TIMESTAMP,
    "BirthPlace" VARCHAR(40),
    "BirthName" VARCHAR(100),
    "NameAddition" VARCHAR(20),
    "Fax" VARCHAR(25),
    "CallName" VARCHAR(50)
);

-- =============================================================================
-- SECTION 2: APPLICANT NORMALIZATION (ApplicantTable → 4 tables)
-- =============================================================================

CREATE TABLE "Nr_Applicants" (
    "Nr_ApplicantID" SERIAL PRIMARY KEY,
    "Nr_UserID" INTEGER,
    "Disability" SMALLINT,
    "MotherTongue" VARCHAR(10),
    "GUID" UUID,
    "Timestamp" BYTEA NOT NULL,
    FOREIGN KEY ("Nr_UserID") REFERENCES "Nr_Users"("UserID")
);

CREATE TABLE "Nr_ApplicantAddress" (
    "Nr_AddressID" SERIAL PRIMARY KEY,
    "Nr_ApplicantID" INTEGER,
    "Street" VARCHAR(120),
    "PostalCode" VARCHAR(10),
    "Residence" VARCHAR(40),
    "Subdistrict" VARCHAR(40),
    "District" VARCHAR(5),
    "State" VARCHAR(3),
    "Country" VARCHAR(4),
    "CountryOfAddress" VARCHAR(50),
    "IsForeignAddress" SMALLINT,
    FOREIGN KEY ("Nr_ApplicantID") REFERENCES "Nr_Applicants"("Nr_ApplicantID") ON DELETE CASCADE
);

-- Note: Nr_ApplicantContact table removed - contact data (email, phone, mobile, fax) is now in Nr_Users table

CREATE TABLE "Nr_ApplicantApplicationInfo" (
    "Nr_ApplicationInfoID" SERIAL PRIMARY KEY,
    "Nr_ApplicantID" INTEGER,
    "Class" VARCHAR(10),
    "TrainingCompany" VARCHAR(20),
    "FormSuffix" VARCHAR(3),
    "GuestStudent" SMALLINT,
    "AdmissionDate" TIMESTAMP,
    "CompanyLock" SMALLINT,
    FOREIGN KEY ("Nr_ApplicantID") REFERENCES "Nr_Applicants"("Nr_ApplicantID") ON DELETE CASCADE
);

-- =============================================================================
-- SECTION 3: GUARDIAN NORMALIZATION (ApplicantGuardianTable → 5 tables)
-- =============================================================================

CREATE TABLE "Nr_ApplicantGuardians" (
    "Nr_GuardianID" SERIAL PRIMARY KEY,
    "Nr_ApplicantID" INTEGER,
    "Nr_UserID" INTEGER,
    "StudentNumber" INTEGER,
    "Category" SMALLINT,
    "Priority" SMALLINT,
    "Salutation" VARCHAR(255),
    "LetterSalutation" VARCHAR(255),
    "Title" VARCHAR(255),
    "Addition" VARCHAR(255),
    "Profession" VARCHAR(255),
    "Denomination" VARCHAR(255),
    "CountryOfBirth" VARCHAR(255),
    "GuardianshipAuthorized" SMALLINT,
    "CustodyAuthorized" SMALLINT,
    "SameHousehold" SMALLINT,
    "CompanyCarrier" SMALLINT,
    "FamilyCode" VARCHAR(255),
    "Remark" VARCHAR(255),
    "Phone2" VARCHAR(255),
    "MobileNumber2" VARCHAR(255),
    "GUID" UUID,
    "XmoodID" UUID,
    "GlobalUID" UUID,
    "Timestamp" BYTEA NOT NULL,
    FOREIGN KEY ("Nr_ApplicantID") REFERENCES "Nr_Applicants"("Nr_ApplicantID") ON DELETE CASCADE,
    FOREIGN KEY ("Nr_UserID") REFERENCES "Nr_Users"("UserID")
);

CREATE TABLE "Nr_ApplicantGuardianAddress" (
    "Nr_GuardianAddressID" SERIAL PRIMARY KEY,
    "Nr_GuardianID" INTEGER,
    "Street" VARCHAR(255),
    "PostalCode" VARCHAR(255),
    "Residence" VARCHAR(255),
    "Subdistrict" VARCHAR(255),
    "State" VARCHAR(255),
    "Country" VARCHAR(255),
    "CountryOfAddress" VARCHAR(255),
    "Country1" VARCHAR(255),
    "Country2" VARCHAR(255),
    "IsForeignAddress" SMALLINT,
    FOREIGN KEY ("Nr_GuardianID") REFERENCES "Nr_ApplicantGuardians"("Nr_GuardianID") ON DELETE CASCADE
);

-- Note: Nr_ApplicantGuardianContact table removed - contact data (email, phone, mobile, fax) is now in Nr_Users table
-- Phone2 and MobileNumber2 are stored in Nr_ApplicantGuardians table

CREATE TABLE "Nr_ApplicantGuardianFinance" (
    "Nr_GuardianFinanceID" SERIAL PRIMARY KEY,
    "Nr_GuardianID" INTEGER,
    "FinancialInstitution" VARCHAR(255),
    "BankCode" VARCHAR(255),
    "AccountNumber" VARCHAR(255),
    "DebtorNumber" VARCHAR(255),
    "Company" VARCHAR(255),
    FOREIGN KEY ("Nr_GuardianID") REFERENCES "Nr_ApplicantGuardians"("Nr_GuardianID") ON DELETE CASCADE
);

CREATE TABLE "Nr_ApplicantGuardianPortal" (
    "Nr_GuardianPortalID" SERIAL PRIMARY KEY,
    "Nr_GuardianID" INTEGER,
    "RegistrationX" SMALLINT,
    "RegistrationName" VARCHAR(255),
    FOREIGN KEY ("Nr_GuardianID") REFERENCES "Nr_ApplicantGuardians"("Nr_GuardianID") ON DELETE CASCADE
);

-- =============================================================================
-- SECTION 4: APPLICANT PROCEDURE DATA NORMALIZATION (3 tables)
-- =============================================================================

CREATE TABLE "Nr_ApplicantProcedureData" (
    "Nr_ProcedureDataID" SERIAL PRIMARY KEY,
    "Nr_ApplicantID" INTEGER,
    "ProcedureNumber" INTEGER,
    "GradeAverage" VARCHAR(255),
    "DocumentsComplete" SMALLINT,
    "ApplicationRejected" SMALLINT,
    "ApplicationWaitlist" SMALLINT,
    "SelectionAccepted" SMALLINT,
    "CurrentApplicant" SMALLINT,
    "ConfirmationSentOn" TIMESTAMP,
    "Remark" VARCHAR(255),
    "GUID" UUID,
    "PortalLastChange" TIMESTAMP,
    "Withdrawn" SMALLINT DEFAULT 0,
    "ApplicationRegistration" TIMESTAMP,
    "IsDraft" SMALLINT DEFAULT 0,
    FOREIGN KEY ("Nr_ApplicantID") REFERENCES "Nr_Applicants"("Nr_ApplicantID") ON DELETE CASCADE,
    FOREIGN KEY ("ProcedureNumber") REFERENCES "Nr_ApplicantProcedure"("Nr_ProcedureID") ON DELETE CASCADE
);

CREATE TABLE "Nr_ApplicantDocuments" (
    "Nr_DocumentID" SERIAL PRIMARY KEY,
    "Nr_ApplicantID" INTEGER,
    "ProcedureNumber" INTEGER,
    "Description" VARCHAR(255),
    "ProcedureGroup" VARCHAR(100),
    "GUID" UUID,
    "Timestamp" BYTEA NOT NULL,
    FOREIGN KEY ("Nr_ApplicantID") REFERENCES "Nr_Applicants"("Nr_ApplicantID") ON DELETE CASCADE,
    FOREIGN KEY ("ProcedureNumber") REFERENCES "Nr_ApplicantProcedure"("Nr_ProcedureID") ON DELETE CASCADE
);

CREATE TABLE "Nr_ApplicantPerformance" (
    "Nr_PerformanceID" SERIAL PRIMARY KEY,
    "Nr_ApplicantID" INTEGER,
    "ProcedureNumber" INTEGER,
    "Position" SMALLINT,
    "Subject" VARCHAR(100),
    "Grade" VARCHAR(50),
    "GUID" UUID,
    "Tenant" SMALLINT DEFAULT 1 NOT NULL,
    "Timestamp" BYTEA NOT NULL,
    FOREIGN KEY ("Nr_ApplicantID") REFERENCES "Nr_Applicants"("Nr_ApplicantID") ON DELETE CASCADE,
    FOREIGN KEY ("ProcedureNumber") REFERENCES "Nr_ApplicantProcedure"("Nr_ProcedureID") ON DELETE CASCADE
);

-- =============================================================================
-- SECTION 5: PROCEDURE CONFIGURATION NORMALIZATION (4 tables)
-- =============================================================================

CREATE TABLE "Nr_ApplicantProcedure" (
    "Nr_ProcedureID" SERIAL PRIMARY KEY,
    "From" TIMESTAMP,
    "To" TIMESTAMP,
    "Description" VARCHAR(255),
    "Description_1" TEXT,
    "GUID" UUID,
    "Tenant" SMALLINT DEFAULT 1 NOT NULL,
    "Timestamp" BYTEA NOT NULL,
    "SchoolID" VARCHAR(255),
    "Status" SMALLINT DEFAULT 1,
    "IsDraft" SMALLINT DEFAULT 0,
    "GradingScale" VARCHAR(255),
    "AgeLimit" INTEGER
);

CREATE TABLE "Nr_ApplicantProcedureDocuments" (
    "Nr_ProcedureDocumentID" SERIAL PRIMARY KEY,
    "ProcedureNumber" INTEGER,
    "ProcedureGroup" VARCHAR(100),
    "Mandatory" SMALLINT,
    "Tenant" SMALLINT DEFAULT 1 NOT NULL,
    FOREIGN KEY ("ProcedureNumber") REFERENCES "Nr_ApplicantProcedure"("Nr_ProcedureID") ON DELETE CASCADE
);

CREATE TABLE "Nr_ApplicantProcedureFieldsConfig" (
    "Nr_FieldsConfigID" SERIAL PRIMARY KEY,
    "ApplicantProcedureNumber" INTEGER NOT NULL,
    "FieldName" VARCHAR(255) NOT NULL,
    "DisplayName" VARCHAR(255) NOT NULL,
    "ConstraintValue" SMALLINT,
    "Required" SMALLINT NOT NULL,
    "DefaultValue" VARCHAR(255),
    "Category" VARCHAR(255),
    "Tenant" SMALLINT DEFAULT 1 NOT NULL,
    "TableNumber" INTEGER,
    "Position" SMALLINT,
    FOREIGN KEY ("ApplicantProcedureNumber") REFERENCES "Nr_ApplicantProcedure"("Nr_ProcedureID") ON DELETE CASCADE
);

CREATE TABLE "Nr_ApplicantProcedureSubjects" (
    "Nr_ProcedureSubjectID" SERIAL PRIMARY KEY,
    "ProcedureNumber" INTEGER NOT NULL,
    "SubjectNumber" INTEGER NOT NULL,
    "Tenant" SMALLINT DEFAULT 1 NOT NULL,
    FOREIGN KEY ("ProcedureNumber") REFERENCES "Nr_ApplicantProcedure"("Nr_ProcedureID") ON DELETE CASCADE
);

-- =============================================================================
-- RELATIONSHIP SUMMARY
-- =============================================================================

-- USER MODULE (Shared):
--   Nr_Users (1) ← (N) Nr_Applicants
--   Nr_Users (1) ← (N) Nr_ApplicantGuardians

-- APPLICANT MODULE:
--   Nr_Applicants (1) ← (1) Nr_ApplicantAddress
--   Note: Contact data (email, phone, mobile, fax) is in Nr_Users table
--   Nr_Applicants (1) ← (1) Nr_ApplicantApplicationInfo
--   Nr_Applicants (1) ← (N) Nr_ApplicantGuardians
--   Nr_Applicants (1) ← (N) Nr_ApplicantProcedureData
--   Nr_Applicants (1) ← (N) Nr_ApplicantDocuments
--   Nr_Applicants (1) ← (N) Nr_ApplicantPerformance

-- GUARDIAN MODULE:
--   Nr_ApplicantGuardians (1) ← (1) Nr_ApplicantGuardianAddress
--   Note: Contact data (email, phone, mobile, fax) is in Nr_Users table
--   Note: Phone2 and MobileNumber2 are stored in Nr_ApplicantGuardians table
--   Nr_ApplicantGuardians (1) ← (1) Nr_ApplicantGuardianFinance
--   Nr_ApplicantGuardians (1) ← (1) Nr_ApplicantGuardianPortal

-- PROCEDURE CONFIGURATION:
--   Nr_ApplicantProcedure (1) ← (N) Nr_ApplicantProcedureDocuments
--   Nr_ApplicantProcedure (1) ← (N) Nr_ApplicantProcedureFieldsConfig
--   Nr_ApplicantProcedure (1) ← (N) Nr_ApplicantProcedureSubjects
--   Nr_ApplicantProcedure (1) ← (N) Nr_ApplicantProcedureData
--   Nr_ApplicantProcedure (1) ← (N) Nr_ApplicantDocuments
--   Nr_ApplicantProcedure (1) ← (N) Nr_ApplicantPerformance

-- =============================================================================
-- SUMMARY: TOTAL TABLES
-- =============================================================================
--
-- TOTAL NORMALIZED TABLES: 14
--
-- Breakdown by category:
--   1. User Module (Shared): 1 table (Nr_Users)
--   2. Applicant Core: 1 table (Nr_Applicants)
--   3. Applicant Details: 2 tables (Nr_ApplicantAddress, Nr_ApplicantApplicationInfo)
--      Note: Contact data is in Nr_Users table
--   4. Guardian Core: 1 table (Nr_ApplicantGuardians)
--      Note: Phone2 and MobileNumber2 are stored in Nr_ApplicantGuardians table
--   5. Guardian Details: 3 tables (Nr_ApplicantGuardianAddress, 
--      Nr_ApplicantGuardianFinance, Nr_ApplicantGuardianPortal)
--      Note: Contact data is in Nr_Users table
--   6. Applicant Procedure Data: 3 tables (Nr_ApplicantProcedureData, Nr_ApplicantDocuments, Nr_ApplicantPerformance)
--   7. Procedure Configuration: 4 tables (Nr_ApplicantProcedure, Nr_ApplicantProcedureDocuments,
--      Nr_ApplicantProcedureFieldsConfig, Nr_ApplicantProcedureSubjects)
--
-- Normalization Pattern:
--   - Names, personal data, SchoolID, TenantID → Nr_Users (following EntityNrStudent pattern)
--   - Contact data (email, phone, mobile, fax) → Nr_Users table (centralized for all users)
--   - Core administrative data → Nr_Applicants / Nr_ApplicantGuardians
--   - Address data → Separate address tables
--   - Secondary contact fields (Phone2, MobileNumber2) → Nr_ApplicantGuardians table
--   - Application-specific data → Separate info tables
--   - Financial data → Separate finance tables
--   - Portal/authentication data → Separate portal tables
--
-- =============================================================================
-- END OF SQL DDL
-- =============================================================================

