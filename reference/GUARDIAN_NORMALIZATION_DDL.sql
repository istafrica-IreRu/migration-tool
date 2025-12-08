-- =====================================================================
-- GUARDIAN TABLE NORMALIZATION - DDL SCRIPT (REVISED)
-- =====================================================================
-- Purpose: Create normalized Guardian tables following Student module pattern
-- Pattern: Splits denormalized GuardianTable into 7 specialized tables
-- Design: Many-to-many relationship between Guardians and Students
-- Compliance: GDPR-compliant with separated sensitive data
-- Reference: backend/src/main/java/com/ist/winschool/Student/internal/entity/
--            autocoding/backend/database/enrollment-normalization.md
-- =====================================================================
--
-- KEY DESIGN DECISION:
-- Guardians and Students have a MANY-TO-MANY relationship:
--   - One guardian can have multiple children (same or different schools)
--   - One student can have multiple guardians (parents, grandparents, etc.)
--   - Junction table (Nr_StudentGuardians) manages relationships
--
-- STRUCTURE:
--   Nr_Guardians - Guardian identity (ONE per person)
--   Nr_StudentGuardians - Junction table (MANY-TO-MANY relationships)
--   Nr_GuardianAddress - Address data (ONE per guardian)
--   Nr_GuardianContact - Contact data (ONE per guardian)
--   Nr_GuardianFinance - Financial data (ONE per guardian, GDPR sensitive)
--   Nr_GuardianEmployment - Employment data (ONE per guardian)
--   Nr_GuardianPortal - Portal access (ONE per guardian, Security sensitive)
-- =====================================================================

-- =====================================================================
-- TABLE 1: Nr_Guardians (Guardian Identity)
-- =====================================================================
-- Purpose: Guardian identity - ONE record per person
-- Contains: Personal identity data, system identifiers
-- Does NOT contain: Student relationships, SchoolID (moved to junction table)
-- Relationships:
--   - References Nr_Users (nullable - guardian may not have user account)
--   - Referenced by Nr_StudentGuardians (junction table)
--   - Referenced by all other Nr_Guardian* tables
-- =====================================================================

CREATE TABLE "Nr_Guardians" (
    "Nr_GuardianID" SERIAL PRIMARY KEY,
    "Nr_UserID" INTEGER NULL,                          -- FK to Nr_Users (nullable - guardian may not have account)
    "GlobalUID" UUID,                                  -- Global unique identifier
    "XmoodID" UUID,                                    -- XMood integration ID
    "Salutation" VARCHAR(50),                          -- Guardian salutation (e.g., Mr., Mrs., Ms., Dr.)
    "Title" VARCHAR(20),                               -- Guardian title (e.g., Prof., Eng., etc.)
    "LetterSalutation" VARCHAR(50),                    -- Formal salutation for letters
    "Timestamp" BYTEA NOT NULL,                        -- Row version for optimistic locking

    -- Foreign Key Constraints
    CONSTRAINT "FK_Nr_Guardians_Nr_Users"
        FOREIGN KEY ("Nr_UserID") REFERENCES "Nr_Users"("UserID") ON DELETE SET NULL,

    -- Unique constraints
    CONSTRAINT "UQ_Nr_Guardians_GlobalUID" UNIQUE ("GlobalUID")
);

-- Indexes for common queries
CREATE INDEX "IDX_Nr_Guardians_UserID" ON "Nr_Guardians"("Nr_UserID");
CREATE INDEX "IDX_Nr_Guardians_XmoodID" ON "Nr_Guardians"("XmoodID");
-- Note: Tenant is obtained from Nr_Users."TenantID" via join, not stored in Nr_Guardians

-- Add comments for documentation
COMMENT ON TABLE "Nr_Guardians" IS 'Guardian identity - ONE record per person. Does not contain student relationships (see Nr_StudentGuardians). Tenant is obtained from linked Nr_Users."TenantID" via join.';
COMMENT ON COLUMN "Nr_Guardians"."Nr_UserID" IS 'Nullable reference to Nr_Users - guardian may not have user account. If present, personal data (Name, FirstName) and TenantID should be in Nr_Users.';
COMMENT ON COLUMN "Nr_Guardians"."GlobalUID" IS 'Global unique identifier for cross-system integration';
COMMENT ON COLUMN "Nr_Guardians"."XmoodID" IS 'XMood platform integration identifier';
COMMENT ON COLUMN "Nr_Guardians"."Salutation" IS 'Guardian salutation (e.g., Mr., Mrs., Ms., Dr.)';
COMMENT ON COLUMN "Nr_Guardians"."Title" IS 'Guardian title (e.g., Prof., Eng., etc.)';
COMMENT ON COLUMN "Nr_Guardians"."LetterSalutation" IS 'Formal salutation for letters and official correspondence';

-- =====================================================================
-- TABLE 2: Nr_StudentGuardians (Junction Table - Many-to-Many)
-- =====================================================================
-- Purpose: Manages many-to-many relationship between Students and Guardians
-- Contains: Relationship-specific data (Category, Priority, Authorization)
-- Examples:
--   - One guardian (Maria) can have 3 children (Anna, Max, Lisa)
--   - One student (Anna) can have 3 guardians (Mother, Father, Grandmother)
-- =====================================================================

CREATE TABLE "Nr_StudentGuardians" (
    "Nr_StudentGuardianID" SERIAL PRIMARY KEY,
    "Nr_StudentID" INTEGER NOT NULL,                  -- FK to Students
    "Nr_GuardianID" INTEGER NOT NULL,                 -- FK to Nr_Guardians
    "SchoolID" VARCHAR(10) NOT NULL,                  -- School identifier (from relationship context)
    "Category" SMALLINT,                              -- Guardian category/type (e.g., Mother, Father, Legal Guardian)
    "Priority" SMALLINT,                              -- Contact priority order (1=primary, 2=secondary, etc.)
    "GuardianshipAuthorized" SMALLINT,                -- Legal guardianship authorization flag
    "CustodyAuthorized" SMALLINT,                     -- Custody authorization flag
    "SameHousehold" SMALLINT,                         -- Lives with student flag
    "FamilyCode" VARCHAR(10),                         -- Family grouping code
    "CompanyCarrier" SMALLINT,                        -- Company carrier flag
    "Denomination" VARCHAR(3),                        -- Religious denomination
    "Addition" VARCHAR(200),                          -- Additional notes about relationship
    "Remark" VARCHAR(255),                            -- General remarks about relationship
    "Tenant" SMALLINT NOT NULL,                       -- Multi-tenant identifier
    "Timestamp" BYTEA NOT NULL,                       -- Row version for optimistic locking

    -- Foreign Key Constraints
    CONSTRAINT "FK_Nr_StudentGuardians_Nr_Students"
        FOREIGN KEY ("Nr_StudentID") REFERENCES "Nr_Students"("Nr_StudentID") ON DELETE CASCADE,
    CONSTRAINT "FK_Nr_StudentGuardians_Nr_Guardians"
        FOREIGN KEY ("Nr_GuardianID") REFERENCES "Nr_Guardians"("Nr_GuardianID") ON DELETE CASCADE,

    -- Unique constraint - prevent duplicate relationships
    CONSTRAINT "UQ_Nr_StudentGuardians_Student_Guardian"
        UNIQUE ("Nr_StudentID", "Nr_GuardianID")
);

-- Indexes for common queries
CREATE INDEX "IDX_Nr_StudentGuardians_StudentID" ON "Nr_StudentGuardians"("Nr_StudentID");
CREATE INDEX "IDX_Nr_StudentGuardians_GuardianID" ON "Nr_StudentGuardians"("Nr_GuardianID");
CREATE INDEX "IDX_Nr_StudentGuardians_SchoolID" ON "Nr_StudentGuardians"("SchoolID");
CREATE INDEX "IDX_Nr_StudentGuardians_FamilyCode" ON "Nr_StudentGuardians"("FamilyCode");
CREATE INDEX "IDX_Nr_StudentGuardians_Priority" ON "Nr_StudentGuardians"("Priority");
CREATE INDEX "IDX_Nr_StudentGuardians_Tenant" ON "Nr_StudentGuardians"("Tenant");

-- Add comments for documentation
COMMENT ON TABLE "Nr_StudentGuardians" IS 'Junction table managing many-to-many relationships between students and guardians. Contains relationship-specific metadata.';
COMMENT ON COLUMN "Nr_StudentGuardians"."Category" IS 'Guardian relationship type (e.g., Mother, Father, Legal Guardian, Emergency Contact)';
COMMENT ON COLUMN "Nr_StudentGuardians"."Priority" IS 'Contact priority order: 1=primary contact, 2=secondary, etc.';
COMMENT ON COLUMN "Nr_StudentGuardians"."GuardianshipAuthorized" IS 'Legal guardianship authorization flag for this student';
COMMENT ON COLUMN "Nr_StudentGuardians"."CustodyAuthorized" IS 'Custody authorization flag for this student';
COMMENT ON COLUMN "Nr_StudentGuardians"."SameHousehold" IS 'Indicates if guardian lives in same household as this student';
COMMENT ON COLUMN "Nr_StudentGuardians"."FamilyCode" IS 'Family grouping code for linking related guardians and students';

-- =====================================================================
-- TABLE 3: Nr_GuardianAddress (Address Data)
-- =====================================================================
-- Purpose: Guardian residential address information
-- Relationships: One-to-one with Nr_Guardians
-- Pattern: Follows Nr_StudentAddress normalization pattern
-- Data Scope: ONE address per guardian (shared across all their children)
-- =====================================================================

CREATE TABLE "Nr_GuardianAddress" (
    "Nr_GuardianAddressID" SERIAL PRIMARY KEY,
    "Nr_GuardianID" INTEGER NOT NULL,                 -- FK to Nr_Guardians
    "Street" VARCHAR(60),                             -- Street address
    "PostalCode" VARCHAR(10),                         -- Postal/ZIP code
    "Residence" VARCHAR(40),                          -- City/Residence
    "Subdistrict" VARCHAR(50),                        -- Subdistrict/Borough
    "State" VARCHAR(3),                               -- State/Province code
    "Country" VARCHAR(30),                            -- Country of residence
    "CountryOfBirth" VARCHAR(30),                     -- Country of birth
    "Country1" VARCHAR(30),                           -- Additional country 1
    "Country2" VARCHAR(30),                           -- Additional country 2

    -- Foreign Key Constraints
    CONSTRAINT "FK_Nr_GuardianAddress_Nr_Guardians"
        FOREIGN KEY ("Nr_GuardianID") REFERENCES "Nr_Guardians"("Nr_GuardianID") ON DELETE CASCADE
);

-- Indexes for common queries
CREATE UNIQUE INDEX "UQ_Nr_GuardianAddress_GuardianID" ON "Nr_GuardianAddress"("Nr_GuardianID");
CREATE INDEX "IDX_Nr_GuardianAddress_PostalCode" ON "Nr_GuardianAddress"("PostalCode");
CREATE INDEX "IDX_Nr_GuardianAddress_Country" ON "Nr_GuardianAddress"("Country");

-- Add comments for documentation
COMMENT ON TABLE "Nr_GuardianAddress" IS 'Guardian address data - ONE per guardian, shared across all their children';
COMMENT ON COLUMN "Nr_GuardianAddress"."Country1" IS 'Additional citizenship country (supports dual/multiple citizenship)';
COMMENT ON COLUMN "Nr_GuardianAddress"."Country2" IS 'Additional citizenship country (supports dual/multiple citizenship)';

-- =====================================================================
-- TABLE 4: Nr_GuardianContact (Additional Contact Information)
-- =====================================================================
-- Purpose: Guardian ADDITIONAL/SECONDARY contact methods
-- Relationships: One-to-one with Nr_Guardians
-- Primary Contact: Email, Phone, Mobile, Fax are in Nr_Users (via Nr_UserID)
-- This Table: Only stores secondary/additional contact methods
-- Data Scope: ONE contact record per guardian (shared across all their children)
--
-- IMPORTANT: Primary contact information (Email, Phone, Mobile, Fax) is stored
-- in the Nr_Users table. This table only stores additional contact methods for
-- complex family arrangements (e.g., second phone, second mobile).
-- =====================================================================

CREATE TABLE "Nr_GuardianContact" (
    "Nr_GuardianContactID" SERIAL PRIMARY KEY,
    "Nr_GuardianID" INTEGER NOT NULL,                 -- FK to Nr_Guardians
    "Phone2" VARCHAR(25),                             -- Secondary phone number
    "MobileNumber2" VARCHAR(30),                      -- Secondary mobile number

    -- Foreign Key Constraints
    CONSTRAINT "FK_Nr_GuardianContact_Nr_Guardians"
        FOREIGN KEY ("Nr_GuardianID") REFERENCES "Nr_Guardians"("Nr_GuardianID") ON DELETE CASCADE
);

-- Indexes for common queries
CREATE UNIQUE INDEX "UQ_Nr_GuardianContact_GuardianID" ON "Nr_GuardianContact"("Nr_GuardianID");
CREATE INDEX "IDX_Nr_GuardianContact_Phone2" ON "Nr_GuardianContact"("Phone2");
CREATE INDEX "IDX_Nr_GuardianContact_MobileNumber2" ON "Nr_GuardianContact"("MobileNumber2");

-- Add comments for documentation
COMMENT ON TABLE "Nr_GuardianContact" IS 'Guardian SECONDARY contact data - ONE per guardian. Primary contact (Email, Phone, Mobile, Fax) stored in Nr_Users.';
COMMENT ON COLUMN "Nr_GuardianContact"."Phone2" IS 'Secondary phone for complex family contact arrangements. Primary phone in Nr_Users.';
COMMENT ON COLUMN "Nr_GuardianContact"."MobileNumber2" IS 'Secondary mobile for complex family contact arrangements. Primary mobile in Nr_Users.';

-- =====================================================================
-- TABLE 5: Nr_GuardianFinance (Financial Data - GDPR Sensitive)
-- =====================================================================
-- Purpose: Banking and financial information
-- Relationships: One-to-one with Nr_Guardians
-- Security: GDPR sensitive - requires enhanced encryption and access controls
-- Compliance: German banking data protection requirements
-- Data Scope: ONE financial record per guardian (shared across all their children)
-- =====================================================================

CREATE TABLE "Nr_GuardianFinance" (
    "Nr_GuardianFinanceID" SERIAL PRIMARY KEY,
    "Nr_GuardianID" INTEGER NOT NULL,                 -- FK to Nr_Guardians
    "FinancialInstitution" VARCHAR(50),               -- Bank name
    "BankCode" VARCHAR(15),                           -- Bank routing/sort code
    "AccountNumber" VARCHAR(34),                      -- IBAN or account number
    "DebtorNumber" VARCHAR(30),                       -- Debtor/customer number

    -- Foreign Key Constraints
    CONSTRAINT "FK_Nr_GuardianFinance_Nr_Guardians"
        FOREIGN KEY ("Nr_GuardianID") REFERENCES "Nr_Guardians"("Nr_GuardianID") ON DELETE CASCADE
);

-- Indexes for common queries
CREATE UNIQUE INDEX "UQ_Nr_GuardianFinance_GuardianID" ON "Nr_GuardianFinance"("Nr_GuardianID");

-- Add comments for documentation
COMMENT ON TABLE "Nr_GuardianFinance" IS 'GDPR SENSITIVE: Guardian financial data - requires enhanced security controls. ONE per guardian, shared across all their children.';
COMMENT ON COLUMN "Nr_GuardianFinance"."AccountNumber" IS 'SENSITIVE: IBAN or account number - must be encrypted at rest';
COMMENT ON COLUMN "Nr_GuardianFinance"."DebtorNumber" IS 'Debtor/customer identification number';

-- Row Level Security (if using PostgreSQL RLS)
-- ALTER TABLE "Nr_GuardianFinance" ENABLE ROW LEVEL SECURITY;

-- =====================================================================
-- TABLE 6: Nr_GuardianEmployment (Employment Information)
-- =====================================================================
-- Purpose: Guardian employment and profession data
-- Relationships: One-to-one with Nr_Guardians
-- Data Scope: ONE employment record per guardian (shared across all their children)
-- =====================================================================

CREATE TABLE "Nr_GuardianEmployment" (
    "Nr_GuardianEmploymentID" SERIAL PRIMARY KEY,
    "Nr_GuardianID" INTEGER NOT NULL,                 -- FK to Nr_Guardians
    "Company" VARCHAR(100),                           -- Employer/company name
    "Profession" VARCHAR(50),                         -- Profession/occupation

    -- Foreign Key Constraints
    CONSTRAINT "FK_Nr_GuardianEmployment_Nr_Guardians"
        FOREIGN KEY ("Nr_GuardianID") REFERENCES "Nr_Guardians"("Nr_GuardianID") ON DELETE CASCADE
);

-- Indexes for common queries
CREATE UNIQUE INDEX "UQ_Nr_GuardianEmployment_GuardianID" ON "Nr_GuardianEmployment"("Nr_GuardianID");

-- Add comments for documentation
COMMENT ON TABLE "Nr_GuardianEmployment" IS 'Guardian employment data - ONE per guardian, shared across all their children';

-- =====================================================================
-- TABLE 7: Nr_GuardianPortal (Portal Access - Security Sensitive)
-- =====================================================================
-- Purpose: Portal registration data
-- Relationships: One-to-one with Nr_Guardians
-- Security: Registration credentials tracked here, password stored in Nr_Users table
-- Note: Password is stored in Nr_Users.PasswordHash, not duplicated here
-- Data Scope: ONE portal access per guardian (shared across all their children)
-- =====================================================================

CREATE TABLE "Nr_GuardianPortal" (
    "Nr_GuardianPortalID" SERIAL PRIMARY KEY,
    "Nr_GuardianID" INTEGER NOT NULL,                 -- FK to Nr_Guardians
    "RegistrationX" SMALLINT,                         -- Registration flag/status
    "RegistrationName" VARCHAR(20),                   -- Registration username

    -- Foreign Key Constraints
    CONSTRAINT "FK_Nr_GuardianPortal_Nr_Guardians"
        FOREIGN KEY ("Nr_GuardianID") REFERENCES "Nr_Guardians"("Nr_GuardianID") ON DELETE CASCADE
);

-- Indexes for common queries
CREATE UNIQUE INDEX "UQ_Nr_GuardianPortal_GuardianID" ON "Nr_GuardianPortal"("Nr_GuardianID");
CREATE UNIQUE INDEX "UQ_Nr_GuardianPortal_RegistrationName" ON "Nr_GuardianPortal"("RegistrationName")
    WHERE "RegistrationName" IS NOT NULL;

-- Add comments for documentation
COMMENT ON TABLE "Nr_GuardianPortal" IS 'SECURITY SENSITIVE: Guardian portal registration data. Password is stored in Nr_Users table. ONE per guardian, shared for viewing all their children.';
COMMENT ON COLUMN "Nr_GuardianPortal"."RegistrationName" IS 'Portal login username - must be unique';

-- =====================================================================
-- EXAMPLE QUERIES
-- =====================================================================

-- Get all guardians for a specific student
-- SELECT g.*, u."FirstName", u."Name"
-- FROM "Nr_StudentGuardians" sg
-- INNER JOIN "Nr_Guardians" g ON sg."Nr_GuardianID" = g."Nr_GuardianID"
-- LEFT JOIN "Nr_Users" u ON g."Nr_UserID" = u."Nr_UserID"
-- WHERE sg."Nr_StudentID" = ?
-- ORDER BY sg."Priority";

-- Get all students for a specific guardian (across all schools)
-- SELECT s.*, sg."SchoolID", sg."Category", sg."Priority"
-- FROM "Nr_StudentGuardians" sg
-- INNER JOIN "Nr_Students" s ON sg."Nr_StudentID" = s."Nr_StudentID"
-- WHERE sg."Nr_GuardianID" = ?
-- ORDER BY sg."SchoolID", sg."Priority";

-- Get complete guardian information with address and contact
-- SELECT g.*, a.*, c.*, e.*
-- FROM "Nr_Guardians" g
-- LEFT JOIN "Nr_GuardianAddress" a ON g."Nr_GuardianID" = a."Nr_GuardianID"
-- LEFT JOIN "Nr_GuardianContact" c ON g."Nr_GuardianID" = c."Nr_GuardianID"
-- LEFT JOIN "Nr_GuardianEmployment" e ON g."Nr_GuardianID" = e."Nr_GuardianID"
-- WHERE g."Nr_GuardianID" = ?;

-- =====================================================================
-- ADDITIONAL CONSIDERATIONS
-- =====================================================================

-- Personal Identity Fields (Name, FirstName, Salutation, etc.)
-- ----------------------------------------------------------------
-- Personal identity fields are split between Nr_Guardians and Nr_Users:
--
-- In Nr_Guardians (guardian-specific personal attributes):
--   - Salutation (e.g., Mr., Mrs., Ms., Dr.)
--   - Title (e.g., Prof., Eng., etc.)
--   - LetterSalutation (formal salutation for letters)
--
-- In Nr_Users (if guardian has Nr_UserID):
--   - FirstName
--   - LastName
--   - Email
--   - Phone
--   - Mobile
--   - Fax
--
-- Note: This approach allows guardians to exist without user accounts
-- while still maintaining their personal attributes in Nr_Guardians.

-- =====================================================================
-- SUMMARY OF NORMALIZATION
-- =====================================================================
-- Original: 1 table (GuardianTable) with 33+ columns
-- Normalized: 7 specialized tables
--   1. Nr_Guardians (8 fields) - Guardian identity + personal attributes (ONE per person)
--                                 Includes: Salutation, Title, LetterSalutation
--                                 Note: Tenant obtained from Nr_Users."TenantID" via join
--   2. Nr_StudentGuardians (15 fields) - Junction table (MANY-TO-MANY)
--   3. Nr_GuardianAddress (11 fields) - Address information
--   4. Nr_GuardianContact (3 fields) - SECONDARY contact methods only
--                                      (Primary: Email, Phone, Mobile, Fax in Nr_Users)
--   5. Nr_GuardianFinance (5 fields) - Financial data (GDPR sensitive)
--   6. Nr_GuardianEmployment (3 fields) - Employment information
--   7. Nr_GuardianPortal (3 fields) - Portal registration (PasswordHash in Nr_Users)
--
-- Key Design Features:
--   ✅ Many-to-Many Relationships - One guardian can have multiple children
--   ✅ No Data Duplication - Guardian data stored once, relationships separate
--   ✅ Contact Info Integration - Primary contact in Nr_Users, secondary in Nr_GuardianContact
--   ✅ Password Security - PasswordHash stored in Nr_Users, not duplicated
--   ✅ GDPR Compliance - Financial data properly isolated
--   ✅ Security - Portal credentials linked via Nr_UserID
--   ✅ Maintainability - Clear separation of concerns
--   ✅ Performance - Smaller tables, better indexes
--   ✅ Flexibility - Easier to modify specific domains
--   ✅ Pattern Consistency - Follows Student module normalization
-- =====================================================================
