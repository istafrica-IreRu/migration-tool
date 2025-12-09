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
-- SECTION 1: USER AND ADDRESS TABLES (Shared with Student Module)
-- =============================================================================
-- Note: Nr_Users and Nr_Addresses tables are defined in V000__create_normalized_users_table.sql
-- They are referenced here for ERD completeness but not created in this script
--
-- Nr_Users table structure:
--   - UserID (PK), LoginName, PasswordHash, FirstName, LastName, Email, Phone, Mobile, Fax
--   - TenantID, SchoolID, Nr_AddressID (FK to Nr_Addresses), and other user fields
--
-- Nr_Addresses table structure:
--   - ID (PK), Street, PostalCode, City, Subdistrict, State, Country
--   - CountryOfAddress, CountryOfBirth, Country1, Country2, IsForeignAddress
--   - AddressType, IsValidated, ValidationDate, Tenant, CreatedAt, UpdatedAt
-- =============================================================================

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

-- Note: Nr_ApplicantContact table removed - contact data (email, phone, mobile, fax) is now in Nr_Users table
-- Note: Nr_ApplicantAddress table removed - addresses are now stored in Nr_Addresses table (User module)

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
-- SECTION 3: GUARDIAN NORMALIZATION (ApplicantGuardianTable → 2 tables)
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
    "RegistrationX" SMALLINT,
    "RegistrationName" VARCHAR(255),
    "Timestamp" BYTEA NOT NULL,
    FOREIGN KEY ("Nr_ApplicantID") REFERENCES "Nr_Applicants"("Nr_ApplicantID") ON DELETE CASCADE,
    FOREIGN KEY ("Nr_UserID") REFERENCES "Nr_Users"("UserID")
);

-- Note: Nr_ApplicantGuardianContact table removed - contact data (email, phone, mobile, fax) is now in Nr_Users table
-- Note: Nr_ApplicantGuardianAddress table removed - addresses are now stored in Nr_Addresses table (User module)
-- Note: Phone2 and MobileNumber2 are stored in Nr_ApplicantGuardians table
-- Note: Portal registration data (RegistrationX, RegistrationName) is now directly in Nr_ApplicantGuardians

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
--   Nr_Users (1) → (1) Nr_Addresses (via Nr_AddressID - relationship reversed)

-- ADDRESS MODULE:
--   Nr_Addresses (1) ← (N) Nr_Users (via Nr_AddressID - relationship reversed)
--   Note: All addresses (applicants, guardians, students, teachers) are stored in Nr_Addresses

-- APPLICANT MODULE:
--   Note: Address data is in Nr_Addresses, linked via Nr_Users.Nr_AddressID
--   Note: Contact data (email, phone, mobile, fax) is in Nr_Users table
--   Nr_Applicants (1) ← (1) Nr_ApplicantApplicationInfo
--   Nr_Applicants (1) ← (N) Nr_ApplicantGuardians
--   Nr_Applicants (1) ← (N) Nr_ApplicantProcedureData
--   Nr_Applicants (1) ← (N) Nr_ApplicantDocuments
--   Nr_Applicants (1) ← (N) Nr_ApplicantPerformance

-- GUARDIAN MODULE:
--   Note: Address data is in Nr_Addresses, linked via Nr_Users.Nr_AddressID (guardians are users)
--   Note: Contact data (email, phone, mobile, fax) is in Nr_Users table
--   Note: Phone2 and MobileNumber2 are stored in Nr_ApplicantGuardians table
--   Note: Portal registration data (RegistrationX, RegistrationName) is now directly in Nr_ApplicantGuardians
--   Nr_ApplicantGuardians (1) ← (1) Nr_ApplicantGuardianFinance

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
-- TOTAL NORMALIZED TABLES: 12
-- (Nr_ApplicantAddress, Nr_ApplicantGuardianAddress, and Nr_ApplicantGuardianPortal removed, Nr_Addresses added)
--
-- Breakdown by category:
--   1. User Module (Shared): 1 table (Nr_Users)
--   2. Address Module (Shared): 1 table (Nr_Addresses)
--      Note: All addresses (applicants, guardians, students, teachers) are stored here
--   3. Applicant Core: 1 table (Nr_Applicants)
--   4. Applicant Details: 1 table (Nr_ApplicantApplicationInfo)
--      Note: Address data is in Nr_Addresses, linked via Nr_Users.Nr_AddressID
--      Note: Contact data is in Nr_Users table
--   5. Guardian Core: 1 table (Nr_ApplicantGuardians)
--      Note: Phone2 and MobileNumber2 are stored in Nr_ApplicantGuardians table
--      Note: Portal registration data (RegistrationX, RegistrationName) is now directly in Nr_ApplicantGuardians
--   6. Guardian Details: 1 table (Nr_ApplicantGuardianFinance)
--      Note: Address data is in Nr_Addresses, linked via Nr_Users.Nr_AddressID (guardians are users)
--      Note: Contact data is in Nr_Users table
--      Note: Portal registration data is now in Nr_ApplicantGuardians
--   6. Applicant Procedure Data: 3 tables (Nr_ApplicantProcedureData, Nr_ApplicantDocuments, Nr_ApplicantPerformance)
--   7. Procedure Configuration: 4 tables (Nr_ApplicantProcedure, Nr_ApplicantProcedureDocuments,
--      Nr_ApplicantProcedureFieldsConfig, Nr_ApplicantProcedureSubjects)
--
-- Normalization Pattern:
--   - Names, personal data, SchoolID, TenantID → Nr_Users (following EntityNrStudent pattern)
--   - Contact data (email, phone, mobile, fax) → Nr_Users table (centralized for all users)
--   - Address data → Nr_Addresses table (centralized for all users - relationship reversed)
--   - Core administrative data → Nr_Applicants / Nr_ApplicantGuardians
--   - Secondary contact fields (Phone2, MobileNumber2) → Nr_ApplicantGuardians table
--   - Portal registration data (RegistrationX, RegistrationName) → Nr_ApplicantGuardians table
--   - Application-specific data → Separate info tables
--   - Financial data → Separate finance tables
--
-- =============================================================================
-- END OF SQL DDL
-- =============================================================================

