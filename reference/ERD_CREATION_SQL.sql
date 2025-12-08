-- =============================================================================
-- SQL DDL for IST-WinSchool Normalized Tables - ERD Generation
-- =============================================================================
-- Generate ERD at: https://www.eraser.io/ai/erd-generator
-- Paste this entire SQL script into the generator
--
-- Project: IST-WinSchool
-- Branch: ch-normalization
-- Database: PostgreSQL
-- =============================================================================

-- =============================================================================
-- SECTION 1: SCHOOL SEMESTERS NORMALIZATION (SchoolSemesters → 2 tables)
-- =============================================================================

CREATE TABLE "NrSchoolSemesters" (
    "ID" SERIAL PRIMARY KEY,
    "OriginalID" INTEGER NOT NULL,
    "SchoolID" VARCHAR(10),
    "StudentNumber" INTEGER NOT NULL,
    "HalfYear" SMALLINT,
    "SemesterText" VARCHAR(6),
    "SchoolSemester" VARCHAR(15),
    "Addition" VARCHAR(5),
    "GradeScale" VARCHAR(20),
    "CertificateDate" TIMESTAMP,
    "ConferenceDate" TIMESTAMP,
    "Promoted" SMALLINT,
    "NumberOfSubjects" SMALLINT,
    "NumberOfRemarks" SMALLINT,
    "DGrade" VARCHAR(10),
    "AdditionGrade" VARCHAR(5),
    "AuditGrade" VARCHAR(5),
    "RepeatedFrom" SMALLINT,
    "RepetitionOrder" SMALLINT,
    "SchoolSemesterType" SMALLINT,
    "FBOK" SMALLINT,
    "FBChecked" SMALLINT,
    "Locked" SMALLINT,
    "DyslexiaInCertificate" SMALLINT,
    "DyslexiaGradeProtection" SMALLINT,
    "ClassTeacher1" VARCHAR(10),
    "ClassTeacher2" VARCHAR(10),
    "SemesterClass" VARCHAR(20),
    "FArea" VARCHAR(7),
    "FuArea" VARCHAR(7),
    "Remark" TEXT,
    "Tenant" SMALLINT NOT NULL,
    "Timestamp" BYTEA NOT NULL,
    "CreatedAt" TIMESTAMP,
    "UpdatedAt" TIMESTAMP
);

CREATE TABLE "NrSchoolSemesterSubjects" (
    "ID" SERIAL PRIMARY KEY,
    "SemesterID" INTEGER NOT NULL,
    "Position" SMALLINT NOT NULL,
    "Subject" VARCHAR(5),
    "GONumber" SMALLINT,
    "Block" VARCHAR(2),
    "CourseNumber" INTEGER,
    "Course" VARCHAR(6),
    "Type" SMALLINT,
    "Grade" VARCHAR(5),
    "Included" SMALLINT,
    "FHR" SMALLINT,
    "Description" VARCHAR(30),
    "Remark" TEXT,
    "CreatedAt" TIMESTAMP,
    "UpdatedAt" TIMESTAMP,
    FOREIGN KEY ("SemesterID") REFERENCES "NrSchoolSemesters"("ID")
);

-- =============================================================================
-- SECTION 2: WILDCARD TABLE NORMALIZATION (WildcardTable → 2 tables)
-- =============================================================================

CREATE TABLE "NrWildcardTable" (
    "ID" SERIAL PRIMARY KEY,
    "OriginalID" INTEGER NOT NULL,
    "RecordNumber" INTEGER,
    "WildcardNumber" INTEGER,
    "CategoryNumber" INTEGER,
    "Tenant" SMALLINT NOT NULL,
    "Timestamp" BYTEA NOT NULL,
    "CreatedAt" TIMESTAMP,
    "UpdatedAt" TIMESTAMP
);

CREATE TABLE "NrWildcardFields" (
    "ID" SERIAL PRIMARY KEY,
    "WildcardID" INTEGER NOT NULL,
    "Position" SMALLINT NOT NULL,
    "FieldValue" VARCHAR(128),
    "CreatedAt" TIMESTAMP,
    "UpdatedAt" TIMESTAMP,
    FOREIGN KEY ("WildcardID") REFERENCES "NrWildcardTable"("ID")
);

-- =============================================================================
-- SECTION 3: SCHOOL CAREER NORMALIZATION (SchoolCareer → 2 tables)
-- =============================================================================

CREATE TABLE "Nr_SchoolCareer" (
    "ID" SERIAL PRIMARY KEY,
    "OriginalStudentNumber" INTEGER NOT NULL,
    "StudentNumber" INTEGER NOT NULL,
    "SchoolID" VARCHAR(10),
    "PreviousSchool" VARCHAR(5),
    "DismissalYear" SMALLINT,
    "Graduation" SMALLINT,
    "Category" VARCHAR(10),
    "InForeignLanguage" VARCHAR(10),
    "Profession" VARCHAR(60),
    "Remark" VARCHAR(200),
    "ShortRemark" VARCHAR(10),
    "Authorization" VARCHAR(10),
    "LastClass" VARCHAR(10),
    "CreditableSchoolYear" SMALLINT,
    "ProfessionalCareer" VARCHAR(3),
    "LastGraduation" VARCHAR(10),
    "GraduationIn" VARCHAR(3),
    "HamburgAbbreviation" SMALLINT,
    "State" VARCHAR(3),
    "LSchool" VARCHAR(40),
    "LEnrollmentDate" TIMESTAMP,
    "EnrollmentDate" TIMESTAMP,
    "SRecommendation" VARCHAR(5),
    "LClassLevel" VARCHAR(5),
    "DepartureTypeTransition" VARCHAR(1),
    "NumberOfYearsForeign" SMALLINT,
    "LGradeForeign" SMALLINT,
    "BTraining" VARCHAR(20),
    "ProfessionalPractice" VARCHAR(20),
    "LastLeadingSign" VARCHAR(10),
    "SchoolAttendanceYears" SMALLINT,
    "DeferralFromSchool" SMALLINT,
    "PreschoolInstitution" VARCHAR(40),
    "EnrollmentSchool" VARCHAR(40),
    "QualificationSecondary1" VARCHAR(5),
    "QualificationSecondary2" VARCHAR(5),
    "LDismissalDate" TIMESTAMP,
    "Origin" VARCHAR(5),
    "CompulsoryEducation" VARCHAR(5),
    "EarlyEnrollment" SMALLINT,
    "NeedAssessment" VARCHAR(10),
    "SiblingFactor" REAL,
    "Classification" VARCHAR(100),
    "CurrentSchoolType" VARCHAR(100),
    "PreDismissalDate" TIMESTAMP,
    "Credit" VARCHAR(2),
    "RecognizedDyslexia" SMALLINT,
    "FederalState" VARCHAR(3),
    "Country" VARCHAR(4),
    "Tenant" SMALLINT NOT NULL,
    "Timestamp" BYTEA NOT NULL,
    "CreatedAt" TIMESTAMP,
    "UpdatedAt" TIMESTAMP
);

CREATE TABLE "Nr_SchoolCareerSubjects" (
    "ID" SERIAL PRIMARY KEY,
    "SchoolCareerID" INTEGER NOT NULL,
    "Position" SMALLINT NOT NULL,
    "Subject" VARCHAR(10),
    "Grade" SMALLINT,
    "Status" VARCHAR(5),
    "CreatedAt" TIMESTAMP,
    "UpdatedAt" TIMESTAMP,
    FOREIGN KEY ("SchoolCareerID") REFERENCES "Nr_SchoolCareer"("ID")
);

-- =============================================================================
-- SECTION 4: STUDENT MODULE NORMALIZATION (Students → 9 tables)
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

CREATE TABLE "Nr_Students" (
    "Nr_StudentID" SERIAL PRIMARY KEY,
    "Nr_UserID" INTEGER,
    "SchoolID" VARCHAR(10),
    "SchoolYear" VARCHAR(2),
    "Class" VARCHAR(10),
    "Curriculum" INTEGER,
    "CurriculumName" VARCHAR(80),
    "Branch" VARCHAR(1),
    "Level" VARCHAR(3),
    "AdmissionDate" DATE,
    "GraduationYear" VARCHAR(2),
    "Status" SMALLINT,
    "YearOfArrival" VARCHAR(4),
    "Country" VARCHAR(4),
    "OfAge" SMALLINT,
    "FinancialAid" SMALLINT,
    "Disability" SMALLINT,
    "Tutor" VARCHAR(5),
    "ProfessionalField" VARCHAR(7),
    "VocationalField2" VARCHAR(3),
    "Specialization" VARCHAR(8),
    "Group" VARCHAR(5),
    "SchoolCategory" VARCHAR(5),
    "TransferDate" TIMESTAMP,
    "CareerStatus" SMALLINT,
    "SchoolDataStatus" SMALLINT,
    "EducationStatus" SMALLINT,
    "FormSuffix" VARCHAR(3),
    "EducationPath" VARCHAR(100),
    "IdentifierCode" VARCHAR(10),
    "DismissalDate" TIMESTAMP,
    "Reason" VARCHAR(50),
    "PartnerSchool" VARCHAR(40),
    "PromotionEligibility" VARCHAR(20),
    "ApprovedUntil" TIMESTAMP,
    "Mentor" VARCHAR(5),
    "DeviationFromStandardTime" VARCHAR(10),
    "Repeater" SMALLINT,
    "RepetitionReason" VARCHAR(50),
    "FreeRepeater" SMALLINT,
    "ResponsibleTrainer" VARCHAR(35),
    "CompanyLock" SMALLINT,
    "RequirementBasis" VARCHAR(100),
    "AdditionalRequirementBasis" VARCHAR(100),
    "Tenant" SMALLINT NOT NULL,
    "Timestamp" BYTEA NOT NULL,
    FOREIGN KEY ("Nr_UserID") REFERENCES "Nr_Users"("UserID")
);

CREATE TABLE "Nr_StudentAddress" (
    "Nr_AddressID" SERIAL PRIMARY KEY,
    "Nr_StudentID" INTEGER,
    "Street" VARCHAR(120),
    "PostalCode" VARCHAR(10),
    "Residence" VARCHAR(40),
    "Subdistrict" VARCHAR(40),
    "District" VARCHAR(5),
    "State" VARCHAR(3),
    "CountryOfAddress" VARCHAR(50),
    "Fax" VARCHAR(25),
    "IsForeignAddress" SMALLINT,
    FOREIGN KEY ("Nr_StudentID") REFERENCES "Nr_Students"("Nr_StudentID")
);

CREATE TABLE "Nr_StudentFamilyInfo" (
    "Nr_FamilyID" SERIAL PRIMARY KEY,
    "Nr_StudentID" INTEGER,
    "LivesWith" VARCHAR(40),
    "MotherTongue" VARCHAR(10),
    "MotherTongue2" VARCHAR(35),
    "Denomination" VARCHAR(3),
    "OfAge" SMALLINT,
    "AsylumSeeker" SMALLINT,
    "Resettler" SMALLINT,
    "Retrainee" SMALLINT,
    "GuestStudent" SMALLINT,
    "FinancialAid" SMALLINT,
    FOREIGN KEY ("Nr_StudentID") REFERENCES "Nr_Students"("Nr_StudentID")
);

CREATE TABLE "Nr_StudentSchoolInfo" (
    "Nr_SchoolInfoID" SERIAL PRIMARY KEY,
    "Nr_StudentID" INTEGER,
    "SchoolYear" VARCHAR(2),
    "SchoolSemester" VARCHAR(15),
    "SchoolSemesterNumber" INTEGER,
    "Class" VARCHAR(10),
    "Profession" VARCHAR(100),
    "Curriculum" INTEGER,
    "CurriculumName" VARCHAR(80),
    "Branch" VARCHAR(1),
    "Level" VARCHAR(3),
    "SchoolCategory" VARCHAR(5),
    "SchoolType" SMALLINT,
    "SchoolTypeText" VARCHAR(50),
    "SchoolYearCode" DOUBLE PRECISION,
    "EntryDate" TIMESTAMP,
    "GraduationYear" VARCHAR(2),
    "SecondLanguageNew" SMALLINT,
    "AdditionalLessons" SMALLINT,
    "EmploymentContract" VARCHAR(20),
    "LastExam" VARCHAR(255),
    "EntryTrainingSemester" VARCHAR(20),
    FOREIGN KEY ("Nr_StudentID") REFERENCES "Nr_Students"("Nr_StudentID")
);

CREATE TABLE "Nr_StudentExam" (
    "Nr_ExamID" SERIAL PRIMARY KEY,
    "Nr_StudentID" INTEGER,
    "ExamRegulation" VARCHAR(3),
    "ExamRegulationText" VARCHAR(50),
    "AbiturGrade" VARCHAR(3),
    "AbiturCertificateDate" TIMESTAMP,
    "Graduation" VARCHAR(10),
    "AdditionalGraduation" VARCHAR(10),
    "Qualification" VARCHAR(3),
    "Reason" VARCHAR(50),
    "AbiturRemark" VARCHAR(255),
    "AbiturChecked" SMALLINT,
    "Grade" VARCHAR(3),
    "AbiturOK" SMALLINT,
    "AbiturConferenceDate" TIMESTAMP,
    "CertificateForm" VARCHAR(8),
    "RecognitionYearFrom" TIMESTAMP,
    "RecognitionYearTo" TIMESTAMP,
    "RecognitionDate" TIMESTAMP,
    FOREIGN KEY ("Nr_StudentID") REFERENCES "Nr_Students"("Nr_StudentID")
);

CREATE TABLE "Nr_StudentFinance" (
    "Nr_FinanceID" SERIAL PRIMARY KEY,
    "Nr_StudentID" INTEGER,
    "FinancialInstitution" VARCHAR(50),
    "BankCode" VARCHAR(15),
    "AccountNumber" VARCHAR(34),
    "FeeObligation" SMALLINT,
    "RetrainingFee" DECIMAL(19,4),
    FOREIGN KEY ("Nr_StudentID") REFERENCES "Nr_Students"("Nr_StudentID")
);

CREATE TABLE "Nr_StudentStatus" (
    "Nr_StatusID" SERIAL PRIMARY KEY,
    "Nr_StudentID" INTEGER,
    "Active" SMALLINT,
    "Archive" SMALLINT,
    "Dismissed" SMALLINT,
    "Disability" SMALLINT,
    "SpecialEducationActive" SMALLINT,
    "ForeignStudent" SMALLINT,
    "PracticalPlaceRequired" SMALLINT,
    "Resettler" SMALLINT,
    "Retrainee" SMALLINT,
    "GuestStudent" SMALLINT,
    "NewApplicant" SMALLINT,
    "PracticalPlace" SMALLINT,
    "GuestStudentBilling" SMALLINT,
    FOREIGN KEY ("Nr_StudentID") REFERENCES "Nr_Students"("Nr_StudentID")
);

CREATE TABLE "Nr_StudentInternship" (
    "Nr_InternshipID" SERIAL PRIMARY KEY,
    "Nr_StudentID" INTEGER,
    "CompanyName" VARCHAR(100),
    "FromDate" TIMESTAMP,
    "ToDate" TIMESTAMP,
    "ContractSigned" SMALLINT,
    "InternshipContract" VARCHAR(20),
    FOREIGN KEY ("Nr_StudentID") REFERENCES "Nr_Students"("Nr_StudentID")
);

-- =============================================================================
-- SECTION 5: ALL TABLE VALUES NORMALIZATION (AllTableValues → 12 tables)
-- =============================================================================

-- TableNumber 508: Differentiations
CREATE TABLE "NrDifferentiations" (
    "ID" SERIAL PRIMARY KEY,
    "OriginalID" INTEGER NOT NULL,
    "VariantNumber" INTEGER,
    "Sorting" SMALLINT,
    "Code" VARCHAR(100),
    "Name" VARCHAR(250),
    "Description" VARCHAR(150),
    "Control" VARCHAR(10),
    "ShowIt" SMALLINT,
    "RDTFlag" SMALLINT,
    "Timestamp" BYTEA NOT NULL,
    "Tenant" SMALLINT NOT NULL,
    "ValidFrom" TIMESTAMP NOT NULL,
    "ValidTo" TIMESTAMP NOT NULL
);

-- TableNumber 510: School Types
CREATE TABLE "NrSchoolTypes" (
    "ID" SERIAL PRIMARY KEY,
    "OriginalID" INTEGER NOT NULL,
    "VariantNumber" INTEGER,
    "Sorting" SMALLINT,
    "Code" VARCHAR(100),
    "Name" VARCHAR(250),
    "Description" VARCHAR(150),
    "Control" VARCHAR(10),
    "ShowIt" SMALLINT,
    "RDTFlag" SMALLINT,
    "Timestamp" BYTEA NOT NULL,
    "Tenant" SMALLINT NOT NULL,
    "ValidFrom" TIMESTAMP NOT NULL,
    "ValidTo" TIMESTAMP NOT NULL
);

-- TableNumber 524: Teaching Forms
CREATE TABLE "NrTeachingForms" (
    "ID" SERIAL PRIMARY KEY,
    "OriginalID" INTEGER NOT NULL,
    "VariantNumber" INTEGER,
    "Sorting" SMALLINT,
    "Code" VARCHAR(100),
    "Name" VARCHAR(250),
    "Description" VARCHAR(150),
    "Control" VARCHAR(10),
    "ShowIt" SMALLINT,
    "RDTFlag" SMALLINT,
    "Timestamp" BYTEA NOT NULL,
    "Tenant" SMALLINT NOT NULL,
    "ValidFrom" TIMESTAMP NOT NULL,
    "ValidTo" TIMESTAMP NOT NULL
);

-- TableNumber 1227: Subject Fields (Aufgabenfeld)
CREATE TABLE "NrSubjectFields" (
    "ID" SERIAL PRIMARY KEY,
    "OriginalID" INTEGER NOT NULL,
    "VariantNumber" INTEGER,
    "Sorting" SMALLINT,
    "Code" VARCHAR(100),
    "Name" VARCHAR(250),
    "Description" VARCHAR(150),
    "Control" VARCHAR(10),
    "ShowIt" SMALLINT,
    "RDTFlag" SMALLINT,
    "Timestamp" BYTEA NOT NULL,
    "Tenant" SMALLINT NOT NULL,
    "ValidFrom" TIMESTAMP NOT NULL,
    "ValidTo" TIMESTAMP NOT NULL,
    "CreatedAt" TIMESTAMP,
    "UpdatedAt" TIMESTAMP
);

-- TableNumber 1233: Grade Scales
CREATE TABLE "NrGradeScales" (
    "ID" SERIAL PRIMARY KEY,
    "OriginalID" INTEGER NOT NULL,
    "VariantNumber" INTEGER,
    "Sorting" SMALLINT,
    "Code" VARCHAR(100),
    "Name" VARCHAR(250),
    "Description" VARCHAR(150),
    "Control" VARCHAR(10),
    "ShowIt" SMALLINT,
    "RDTFlag" SMALLINT,
    "Timestamp" BYTEA NOT NULL,
    "Tenant" SMALLINT NOT NULL,
    "ValidFrom" TIMESTAMP NOT NULL,
    "ValidTo" TIMESTAMP NOT NULL
);

-- TableNumber 1254: Subjects (Languages, Courses, etc.)
CREATE TABLE "NrSubjects" (
    "ID" SERIAL PRIMARY KEY,
    "OriginalID" INTEGER NOT NULL,
    "VariantNumber" INTEGER,
    "Sorting" SMALLINT,
    "Code" VARCHAR(100),
    "Name" VARCHAR(250),
    "Description" VARCHAR(150),
    "Control" VARCHAR(10),
    "ShowIt" SMALLINT,
    "RDTFlag" SMALLINT,
    "Timestamp" BYTEA NOT NULL,
    "Tenant" SMALLINT NOT NULL,
    "ValidFrom" TIMESTAMP NOT NULL,
    "ValidTo" TIMESTAMP NOT NULL,
    "CreatedAt" TIMESTAMP,
    "UpdatedAt" TIMESTAMP
);

-- TableNumber 1255: Art Types (Grade classifications)
CREATE TABLE "NrArtTypes" (
    "ID" SERIAL PRIMARY KEY,
    "OriginalID" INTEGER NOT NULL,
    "VariantNumber" INTEGER,
    "Sorting" SMALLINT,
    "Code" VARCHAR(100),
    "Name" VARCHAR(250),
    "Description" VARCHAR(150),
    "Control" VARCHAR(10),
    "ShowIt" SMALLINT,
    "RDTFlag" SMALLINT,
    "Timestamp" BYTEA NOT NULL,
    "Tenant" SMALLINT NOT NULL,
    "ValidFrom" TIMESTAMP NOT NULL,
    "ValidTo" TIMESTAMP NOT NULL
);

-- TableNumber 2000: Education Paths
CREATE TABLE "NrEducationPaths" (
    "ID" SERIAL PRIMARY KEY,
    "OriginalID" INTEGER NOT NULL,
    "VariantNumber" INTEGER,
    "Sorting" SMALLINT,
    "Code" VARCHAR(100),
    "Name" VARCHAR(250),
    "Description" VARCHAR(150),
    "Control" VARCHAR(10),
    "ShowIt" SMALLINT,
    "RDTFlag" SMALLINT,
    "Timestamp" BYTEA NOT NULL,
    "Tenant" SMALLINT NOT NULL,
    "ValidFrom" TIMESTAMP NOT NULL,
    "ValidTo" TIMESTAMP NOT NULL
);

-- TableNumber 5007: Course Types
CREATE TABLE "NrCourseTypes" (
    "ID" SERIAL PRIMARY KEY,
    "OriginalID" INTEGER NOT NULL,
    "VariantNumber" INTEGER,
    "Sorting" SMALLINT,
    "Code" VARCHAR(100),
    "Name" VARCHAR(250),
    "Description" VARCHAR(150),
    "Control" VARCHAR(10),
    "ShowIt" SMALLINT,
    "RDTFlag" SMALLINT,
    "Timestamp" BYTEA NOT NULL,
    "Tenant" SMALLINT NOT NULL,
    "ValidFrom" TIMESTAMP NOT NULL,
    "ValidTo" TIMESTAMP NOT NULL
);

-- TableNumber 5012: Class Levels
CREATE TABLE "NrClassLevels" (
    "ID" SERIAL PRIMARY KEY,
    "OriginalID" INTEGER NOT NULL,
    "VariantNumber" INTEGER,
    "Sorting" SMALLINT,
    "Code" VARCHAR(100),
    "Name" VARCHAR(250),
    "Description" VARCHAR(150),
    "Control" VARCHAR(10),
    "ShowIt" SMALLINT,
    "RDTFlag" SMALLINT,
    "Timestamp" BYTEA NOT NULL,
    "Tenant" SMALLINT NOT NULL,
    "ValidFrom" TIMESTAMP NOT NULL,
    "ValidTo" TIMESTAMP NOT NULL
);

-- TableNumber 5013: Learning Fields
CREATE TABLE "NrLearningFields" (
    "ID" SERIAL PRIMARY KEY,
    "OriginalID" INTEGER NOT NULL,
    "VariantNumber" INTEGER,
    "Sorting" SMALLINT,
    "Code" VARCHAR(100),
    "Name" VARCHAR(250),
    "Description" VARCHAR(150),
    "Control" VARCHAR(10),
    "ShowIt" SMALLINT,
    "RDTFlag" SMALLINT,
    "Timestamp" BYTEA NOT NULL,
    "Tenant" SMALLINT NOT NULL,
    "ValidFrom" TIMESTAMP NOT NULL,
    "ValidTo" TIMESTAMP NOT NULL
);

-- TableNumber 1340: Correspondence Types
CREATE TABLE "NrCorrespondenceTypes" (
    "ID" SERIAL PRIMARY KEY,
    "OriginalID" INTEGER NOT NULL,
    "VariantNumber" INTEGER,
    "Sorting" SMALLINT,
    "Code" VARCHAR(100),
    "Name" VARCHAR(250),
    "Description" VARCHAR(150),
    "Control" VARCHAR(10),
    "ShowIt" SMALLINT,
    "RDTFlag" SMALLINT,
    "Timestamp" BYTEA NOT NULL,
    "Tenant" SMALLINT NOT NULL,
    "ValidFrom" TIMESTAMP NOT NULL,
    "ValidTo" TIMESTAMP NOT NULL
);

-- =============================================================================
-- SECTION 6: ADDRESS NORMALIZATION (GuardianTable, Teachers → 3 tables)
-- =============================================================================

CREATE TABLE "Nr_Addresses" (
    "ID" SERIAL PRIMARY KEY,
    "Street" VARCHAR(120),
    "PostalCode" VARCHAR(10),
    "City" VARCHAR(40),
    "Subdistrict" VARCHAR(50),
    "State" VARCHAR(3),
    "Country" VARCHAR(4),
    "AddressType" VARCHAR(20),
    "IsValidated" SMALLINT DEFAULT 0,
    "ValidationDate" TIMESTAMP,
    "Tenant" SMALLINT NOT NULL,
    "CreatedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    "UpdatedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE "Nr_GuardianAddresses" (
    "ID" SERIAL PRIMARY KEY,
    "GuardianID" INTEGER NOT NULL,
    "AddressID" INTEGER NOT NULL,
    "OriginalGuardianID" INTEGER,
    "IsPrimary" SMALLINT DEFAULT 1,
    "AddressLabel" VARCHAR(50),
    "CreatedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    "UpdatedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY ("AddressID") REFERENCES "Nr_Addresses"("ID")
);

CREATE TABLE "Nr_TeacherAddresses" (
    "ID" SERIAL PRIMARY KEY,
    "TeacherID" INTEGER NOT NULL,
    "AddressID" INTEGER NOT NULL,
    "OriginalTeacherID" INTEGER,
    "IsPrimary" SMALLINT DEFAULT 1,
    "AddressLabel" VARCHAR(50),
    "CreatedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    "UpdatedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY ("AddressID") REFERENCES "Nr_Addresses"("ID")
);

-- =============================================================================
-- SECTION 7: CLASSES NORMALIZATION (Classes → Nr_Classes)
-- =============================================================================

CREATE TABLE "Nr_Classes" (
    "ID" SERIAL PRIMARY KEY,
    "OriginalID" INTEGER NOT NULL,
    "SchoolID" VARCHAR(10),
    "SchoolYear" VARCHAR(2),
    "SchoolSemester" VARCHAR(15),
    "Description" VARCHAR(150),
    "ShortName" VARCHAR(10),
    "SchoolCategory" VARCHAR(5),
    "ClassLevel" VARCHAR(3),
    "ClassTeacher" VARCHAR(5),
    "MaxStudents" SMALLINT,
    "TeachingForm" VARCHAR(1),
    "ClassCategory" VARCHAR(40),
    "Classroom" VARCHAR(10),
    "Differentiation" VARCHAR(2),
    "DefaultCurriculum" INTEGER,
    "BlockGroup" VARCHAR(10),
    "RequirementBasis" VARCHAR(50),
    "BlockKey" VARCHAR(100),
    "BlockType" VARCHAR(20),
    "Remarks" VARCHAR(100),
    "Department" VARCHAR(10),
    "EducationPath" VARCHAR(100),
    "Specialization" VARCHAR(50),
    "Branch" VARCHAR(30),
    "Course" SMALLINT,
    "OfficialName" VARCHAR(30),
    "EthicsClass" SMALLINT DEFAULT 0,
    "SpecialFeature" VARCHAR(2),
    "BranchOffice" VARCHAR(1),
    "ExplanationFeature" VARCHAR(2),
    "BlockWeeksCount" SMALLINT,
    "Statistics" SMALLINT DEFAULT 0,
    "ProfessionalField" VARCHAR(3),
    "Profession" VARCHAR(60),
    "Level" VARCHAR(2),
    "VocationalField2" VARCHAR(3),
    "IdentifierCode" VARCHAR(10),
    "SchoolPart" VARCHAR(5),
    "DeputyClassTeacher" VARCHAR(5),
    "ClassType" VARCHAR(2),
    "Qualification" VARCHAR(3),
    "CrossCountryVocationalClasses" SMALLINT,
    "ApplicantClass" SMALLINT DEFAULT 0,
    "InTimetable" SMALLINT DEFAULT 0,
    "ClassTeacherHours" REAL,
    "ClassHours" REAL,
    "Timestamp" BYTEA NOT NULL,
    "UntisID" VARCHAR(50),
    "Tenant" SMALLINT NOT NULL,
    "XmoodID" UUID,
    "GlobalUID" UUID,
    "GraduationClass" SMALLINT DEFAULT 0 NOT NULL
);

-- =============================================================================
-- SECTION 8: TABLE VALUES EXTENDED NORMALIZATION (TableValuesExtended → 2 tables)
-- =============================================================================

CREATE TABLE "NrTableValuesExtended" (
    "ID" SERIAL PRIMARY KEY,
    "OriginalID" INTEGER NOT NULL,
    "TableNumber" SMALLINT,
    "Control" VARCHAR(20),
    "ShowIt" SMALLINT,
    "RDTFlag" SMALLINT,
    "Timestamp" BYTEA NOT NULL,
    "Tenant" SMALLINT NOT NULL,
    "ValidFrom" TIMESTAMP DEFAULT '1900-01-01 00:00:00' NOT NULL,
    "ValidTo" TIMESTAMP DEFAULT '2099-01-01 00:00:00' NOT NULL
);

CREATE TABLE "NrTableExtendedValues" (
    "ID" SERIAL PRIMARY KEY,
    "ExtendedTableID" INTEGER NOT NULL,
    "Position" SMALLINT NOT NULL,
    "Value" VARCHAR(50),
    "Tenant" SMALLINT NOT NULL,
    FOREIGN KEY ("ExtendedTableID") REFERENCES "NrTableValuesExtended"("ID")
);

-- =============================================================================
-- RELATIONSHIP SUMMARY
-- =============================================================================

-- SCHOOL SEMESTERS:
--   NrSchoolSemesters (1) ← (N) NrSchoolSemesterSubjects

-- WILDCARD TABLE:
--   NrWildcardTable (1) ← (N) NrWildcardFields

-- SCHOOL CAREER:
--   Nr_SchoolCareer (1) ← (N) Nr_SchoolCareerSubjects

-- STUDENT MODULE:
--   Nr_Users (1) ← (N) Nr_Students
--   Nr_Students (1) ← (1) Nr_StudentAddress
--   Nr_Students (1) ← (1) Nr_StudentFamilyInfo
--   Nr_Students (1) ← (1) Nr_StudentSchoolInfo
--   Nr_Students (1) ← (1) Nr_StudentExam
--   Nr_Students (1) ← (1) Nr_StudentFinance
--   Nr_Students (1) ← (1) Nr_StudentStatus
--   Nr_Students (1) ← (N) Nr_StudentInternship

-- ALL TABLE VALUES:
--   Independent lookup tables (no relationships):
--   - NrDifferentiations (TableNumber 508)
--   - NrSchoolTypes (TableNumber 510)
--   - NrTeachingForms (TableNumber 524)
--   - NrSubjectFields (TableNumber 1227)
--   - NrGradeScales (TableNumber 1233)
--   - NrSubjects (TableNumber 1254)
--   - NrArtTypes (TableNumber 1255)
--   - NrCorrespondenceTypes (TableNumber 1340)
--   - NrEducationPaths (TableNumber 2000)
--   - NrCourseTypes (TableNumber 5007)
--   - NrClassLevels (TableNumber 5012)
--   - NrLearningFields (TableNumber 5013)

-- ADDRESS NORMALIZATION:
--   Nr_Addresses (1) ← (N) Nr_GuardianAddresses
--   Nr_Addresses (1) ← (N) Nr_TeacherAddresses

-- CLASSES:
--   Nr_Classes (standalone table, no child tables)

-- TABLE VALUES EXTENDED:
--   NrTableValuesExtended (1) ← (N) NrTableExtendedValues

-- =============================================================================
-- SUMMARY: TOTAL TABLES
-- =============================================================================
--
-- TOTAL NORMALIZED TABLES: 38
--
-- Breakdown by category:
--   1. School Semesters: 2 tables (NrSchoolSemesters, NrSchoolSemesterSubjects)
--   2. Wildcard: 2 tables (NrWildcardTable, NrWildcardFields)
--   3. School Career: 2 tables (Nr_SchoolCareer, Nr_SchoolCareerSubjects)
--   4. Student Module: 9 tables (Nr_Users, Nr_Students + 7 related tables)
--   5. AllTableValues: 12 lookup tables
--   6. Address: 3 tables (Nr_Addresses, Nr_GuardianAddresses, Nr_TeacherAddresses)
--   7. Classes: 1 table (Nr_Classes)
--   8. Table Values Extended: 2 tables (NrTableValuesExtended, NrTableExtendedValues)
--
-- =============================================================================
-- END OF SQL DDL
-- =============================================================================
