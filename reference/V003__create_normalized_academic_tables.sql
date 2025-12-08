-- Migration: Create Normalized Academic Module Tables
-- Description: Creates normalized tables for academic module (subjects, rooms, teachers, classes, curricula) following 3NF
-- Database: PostgreSQL
-- Date: 2025-01-27

-- Note: Flyway automatically wraps this migration in a transaction
-- No explicit BEGIN/COMMIT needed

-- ============================================================================
-- Phase 1: Create Reference Tables (No Dependencies)
-- ============================================================================

-- Create Nr_Subjects table (Reference table for subjects - no dependencies)
CREATE TABLE IF NOT EXISTS "Nr_Subjects" (
    "Nr_SubjectID" INTEGER NOT NULL,
    "SubjectCode" CHARACTER VARYING(10),      -- Unique code for the subject
    "SubjectName" CHARACTER VARYING(150),     -- Full name of the subject
    "ShortName" CHARACTER VARYING(10),        -- Short abbreviation
    "SubjectType" CHARACTER VARYING(5),       -- Type identifier (e.g., '1' for language, '2' for social studies, '3' for science)
    "SubjectArea" CHARACTER VARYING(10),      -- Subject area grouping
    "SubjectSubarea" CHARACTER VARYING(10),   -- More specific subject sub-area
    "SubjectPosition" SMALLINT,               -- Position or ordering in curriculum
    "SchoolID" CHARACTER VARYING(10),         -- School identifier for multi-school systems
    "Tenant" SMALLINT DEFAULT 1 NOT NULL,
    "Timestamp" BYTEA NOT NULL,
    "Status" SMALLINT DEFAULT 1,              -- Status field (1=active, 0=inactive) instead of deletion
    "XmoodID" UUID,
    "GlobalUID" UUID,
    CONSTRAINT "Nr_Subjects_pkey" PRIMARY KEY ("Nr_SubjectID")
);

-- Create sequence for Nr_Subjects
CREATE SEQUENCE IF NOT EXISTS "Nr_Subjects_Nr_SubjectID_seq"
    AS INTEGER
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE "Nr_Subjects" ALTER COLUMN "Nr_SubjectID" SET DEFAULT nextval('"Nr_Subjects_Nr_SubjectID_seq"');
ALTER SEQUENCE "Nr_Subjects_Nr_SubjectID_seq" OWNED BY "Nr_Subjects"."Nr_SubjectID";

-- Create indexes
CREATE INDEX IF NOT EXISTS "idx_Nr_Subjects_SubjectCode" ON "Nr_Subjects"("SubjectCode");
CREATE INDEX IF NOT EXISTS "idx_Nr_Subjects_SchoolID" ON "Nr_Subjects"("SchoolID");
CREATE INDEX IF NOT EXISTS "idx_Nr_Subjects_Status" ON "Nr_Subjects"("Status");

COMMENT ON TABLE "Nr_Subjects" IS 'Reference table for subjects - no dependencies';

-- Create Nr_Rooms table (Reference table for rooms - no dependencies)
CREATE TABLE IF NOT EXISTS "Nr_Rooms" (
    "Nr_RoomID" INTEGER NOT NULL,
    "RoomNumber" CHARACTER VARYING(10),       -- Room identifier (number or name)
    "RoomName" CHARACTER VARYING(50),         -- Full room name
    "RoomType" CHARACTER VARYING(20),         -- Type of room (classroom, lab, gym, etc.)
    "Capacity" SMALLINT,                      -- Maximum capacity of the room
    "SchoolID" CHARACTER VARYING(10),         -- School identifier for multi-school systems
    "Building" CHARACTER VARYING(50),         -- Building where the room is located
    "Floor" CHARACTER VARYING(10),            -- Floor number
    "Tenant" SMALLINT DEFAULT 1 NOT NULL,
    "Timestamp" BYTEA NOT NULL,
    "Status" SMALLINT DEFAULT 1,              -- Status field (1=active, 0=inactive) instead of deletion
    "XmoodID" UUID,
    "GlobalUID" UUID,
    CONSTRAINT "Nr_Rooms_pkey" PRIMARY KEY ("Nr_RoomID")
);

-- Create sequence for Nr_Rooms
CREATE SEQUENCE IF NOT EXISTS "Nr_Rooms_Nr_RoomID_seq"
    AS INTEGER
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE "Nr_Rooms" ALTER COLUMN "Nr_RoomID" SET DEFAULT nextval('"Nr_Rooms_Nr_RoomID_seq"');
ALTER SEQUENCE "Nr_Rooms_Nr_RoomID_seq" OWNED BY "Nr_Rooms"."Nr_RoomID";

-- Create indexes
CREATE INDEX IF NOT EXISTS "idx_Nr_Rooms_RoomNumber" ON "Nr_Rooms"("RoomNumber");
CREATE INDEX IF NOT EXISTS "idx_Nr_Rooms_SchoolID" ON "Nr_Rooms"("SchoolID");
CREATE INDEX IF NOT EXISTS "idx_Nr_Rooms_Status" ON "Nr_Rooms"("Status");

COMMENT ON TABLE "Nr_Rooms" IS 'Reference table for rooms - no dependencies';

-- Create Nr_SchoolYears table (Reference table for school years)
CREATE TABLE IF NOT EXISTS "Nr_SchoolYears" (
    "Nr_SchoolYearID" INTEGER NOT NULL,
    "YearCode" CHARACTER VARYING(10),
    "Description" CHARACTER VARYING(50),
    "StartDate" DATE,
    "EndDate" DATE,
    "SchoolID" CHARACTER VARYING(10),
    "Tenant" SMALLINT DEFAULT 1 NOT NULL,
    "Timestamp" BYTEA NOT NULL,
    "Status" SMALLINT DEFAULT 1,              -- Status field (1=active, 0=inactive)
    "XmoodID" UUID,
    "GlobalUID" UUID,
    CONSTRAINT "Nr_SchoolYears_pkey" PRIMARY KEY ("Nr_SchoolYearID")
);

-- Create sequence for Nr_SchoolYears
CREATE SEQUENCE IF NOT EXISTS "Nr_SchoolYears_Nr_SchoolYearID_seq"
    AS INTEGER
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE "Nr_SchoolYears" ALTER COLUMN "Nr_SchoolYearID" SET DEFAULT nextval('"Nr_SchoolYears_Nr_SchoolYearID_seq"');
ALTER SEQUENCE "Nr_SchoolYears_Nr_SchoolYearID_seq" OWNED BY "Nr_SchoolYears"."Nr_SchoolYearID";

-- Create indexes
CREATE INDEX IF NOT EXISTS "idx_Nr_SchoolYears_YearCode" ON "Nr_SchoolYears"("YearCode");
CREATE INDEX IF NOT EXISTS "idx_Nr_SchoolYears_SchoolID" ON "Nr_SchoolYears"("SchoolID");

COMMENT ON TABLE "Nr_SchoolYears" IS 'Reference table for school years';

-- Create Nr_SchoolSemesters table (Reference table for school semesters)
CREATE TABLE IF NOT EXISTS "Nr_SchoolSemesters" (
    "Nr_SchoolSemesterID" INTEGER NOT NULL,
    "SemesterCode" CHARACTER VARYING(15),
    "Description" CHARACTER VARYING(50),
    "StartDate" DATE,
    "EndDate" DATE,
    "SchoolID" CHARACTER VARYING(10),
    "Tenant" SMALLINT DEFAULT 1 NOT NULL,
    "Timestamp" BYTEA NOT NULL,
    "Status" SMALLINT DEFAULT 1,              -- Status field (1=active, 0=inactive)
    "XmoodID" UUID,
    "GlobalUID" UUID,
    CONSTRAINT "Nr_SchoolSemesters_pkey" PRIMARY KEY ("Nr_SchoolSemesterID")
);

-- Create sequence for Nr_SchoolSemesters
CREATE SEQUENCE IF NOT EXISTS "Nr_SchoolSemesters_Nr_SchoolSemesterID_seq"
    AS INTEGER
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE "Nr_SchoolSemesters" ALTER COLUMN "Nr_SchoolSemesterID" SET DEFAULT nextval('"Nr_SchoolSemesters_Nr_SchoolSemesterID_seq"');
ALTER SEQUENCE "Nr_SchoolSemesters_Nr_SchoolSemesterID_seq" OWNED BY "Nr_SchoolSemesters"."Nr_SchoolSemesterID";

-- Create indexes
CREATE INDEX IF NOT EXISTS "idx_Nr_SchoolSemesters_SemesterCode" ON "Nr_SchoolSemesters"("SemesterCode");
CREATE INDEX IF NOT EXISTS "idx_Nr_SchoolSemesters_SchoolID" ON "Nr_SchoolSemesters"("SchoolID");

COMMENT ON TABLE "Nr_SchoolSemesters" IS 'Reference table for school semesters - addresses critical semester reference issue';

-- Create Nr_SchoolCategories table (Reference table for school categories)
CREATE TABLE IF NOT EXISTS "Nr_SchoolCategories" (
    "Nr_SchoolCategoryID" INTEGER NOT NULL,
    "Name" CHARACTER VARYING(100),
    "Code" CHARACTER VARYING(10),
    "Description" TEXT,
    "SchoolID" CHARACTER VARYING(10),
    "Tenant" SMALLINT DEFAULT 1 NOT NULL,
    "Timestamp" BYTEA NOT NULL,
    "Status" SMALLINT DEFAULT 1,              -- Status field (1=active, 0=inactive)
    "XmoodID" UUID,
    "GlobalUID" UUID,
    CONSTRAINT "Nr_SchoolCategories_pkey" PRIMARY KEY ("Nr_SchoolCategoryID")
);

-- Create sequence for Nr_SchoolCategories
CREATE SEQUENCE IF NOT EXISTS "Nr_SchoolCategories_Nr_SchoolCategoryID_seq"
    AS INTEGER
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE "Nr_SchoolCategories" ALTER COLUMN "Nr_SchoolCategoryID" SET DEFAULT nextval('"Nr_SchoolCategories_Nr_SchoolCategoryID_seq"');
ALTER SEQUENCE "Nr_SchoolCategories_Nr_SchoolCategoryID_seq" OWNED BY "Nr_SchoolCategories"."Nr_SchoolCategoryID";

-- Create indexes
CREATE INDEX IF NOT EXISTS "idx_Nr_SchoolCategories_Code" ON "Nr_SchoolCategories"("Code");
CREATE INDEX IF NOT EXISTS "idx_Nr_SchoolCategories_SchoolID" ON "Nr_SchoolCategories"("SchoolID");

-- Create Nr_SchoolTypes table (Reference table for school types)
CREATE TABLE IF NOT EXISTS "Nr_SchoolTypes" (
    "Nr_SchoolTypeID" INTEGER NOT NULL,
    "Name" CHARACTER VARYING(100),
    "Code" CHARACTER VARYING(10),
    "Description" TEXT,
    "SchoolID" CHARACTER VARYING(10),
    "Tenant" SMALLINT DEFAULT 1 NOT NULL,
    "Timestamp" BYTEA NOT NULL,
    "Status" SMALLINT DEFAULT 1,              -- Status field (1=active, 0=inactive)
    "XmoodID" UUID,
    "GlobalUID" UUID,
    CONSTRAINT "Nr_SchoolTypes_pkey" PRIMARY KEY ("Nr_SchoolTypeID")
);

-- Create sequence for Nr_SchoolTypes
CREATE SEQUENCE IF NOT EXISTS "Nr_SchoolTypes_Nr_SchoolTypeID_seq"
    AS INTEGER
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE "Nr_SchoolTypes" ALTER COLUMN "Nr_SchoolTypeID" SET DEFAULT nextval('"Nr_SchoolTypes_Nr_SchoolTypeID_seq"');
ALTER SEQUENCE "Nr_SchoolTypes_Nr_SchoolTypeID_seq" OWNED BY "Nr_SchoolTypes"."Nr_SchoolTypeID";

-- Create indexes
CREATE INDEX IF NOT EXISTS "idx_Nr_SchoolTypes_Code" ON "Nr_SchoolTypes"("Code");

-- Create Nr_Professions table (Reference table for professions)
CREATE TABLE IF NOT EXISTS "Nr_Professions" (
    "Nr_ProfessionID" INTEGER NOT NULL,
    "Name" CHARACTER VARYING(100),
    "Code" CHARACTER VARYING(10),
    "Description" TEXT,
    "SchoolID" CHARACTER VARYING(10),
    "Tenant" SMALLINT DEFAULT 1 NOT NULL,
    "Timestamp" BYTEA NOT NULL,
    "Status" SMALLINT DEFAULT 1,              -- Status field (1=active, 0=inactive)
    "XmoodID" UUID,
    "GlobalUID" UUID,
    CONSTRAINT "Nr_Professions_pkey" PRIMARY KEY ("Nr_ProfessionID")
);

-- Create sequence for Nr_Professions
CREATE SEQUENCE IF NOT EXISTS "Nr_Professions_Nr_ProfessionID_seq"
    AS INTEGER
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE "Nr_Professions" ALTER COLUMN "Nr_ProfessionID" SET DEFAULT nextval('"Nr_Professions_Nr_ProfessionID_seq"');
ALTER SEQUENCE "Nr_Professions_Nr_ProfessionID_seq" OWNED BY "Nr_Professions"."Nr_ProfessionID";

-- Create indexes
CREATE INDEX IF NOT EXISTS "idx_Nr_Professions_Code" ON "Nr_Professions"("Code");

-- Create Nr_ProfessionalFields table (Reference table for professional fields)
CREATE TABLE IF NOT EXISTS "Nr_ProfessionalFields" (
    "Nr_ProfessionalFieldID" INTEGER NOT NULL,
    "Name" CHARACTER VARYING(100),
    "Code" CHARACTER VARYING(10),
    "Description" TEXT,
    "SchoolID" CHARACTER VARYING(10),
    "Tenant" SMALLINT DEFAULT 1 NOT NULL,
    "Timestamp" BYTEA NOT NULL,
    "Status" SMALLINT DEFAULT 1,              -- Status field (1=active, 0=inactive)
    "XmoodID" UUID,
    "GlobalUID" UUID,
    CONSTRAINT "Nr_ProfessionalFields_pkey" PRIMARY KEY ("Nr_ProfessionalFieldID")
);

-- Create sequence for Nr_ProfessionalFields
CREATE SEQUENCE IF NOT EXISTS "Nr_ProfessionalFields_Nr_ProfessionalFieldID_seq"
    AS INTEGER
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE "Nr_ProfessionalFields" ALTER COLUMN "Nr_ProfessionalFieldID" SET DEFAULT nextval('"Nr_ProfessionalFields_Nr_ProfessionalFieldID_seq"');
ALTER SEQUENCE "Nr_ProfessionalFields_Nr_ProfessionalFieldID_seq" OWNED BY "Nr_ProfessionalFields"."Nr_ProfessionalFieldID";

-- Create indexes
CREATE INDEX IF NOT EXISTS "idx_Nr_ProfessionalFields_Code" ON "Nr_ProfessionalFields"("Code");

-- Create Nr_VocationalFields table (Reference table for vocational fields)
CREATE TABLE IF NOT EXISTS "Nr_VocationalFields" (
    "Nr_VocationalFieldID" INTEGER NOT NULL,
    "Name" CHARACTER VARYING(100),
    "Code" CHARACTER VARYING(10),
    "Description" TEXT,
    "SchoolID" CHARACTER VARYING(10),
    "Tenant" SMALLINT DEFAULT 1 NOT NULL,
    "Timestamp" BYTEA NOT NULL,
    "Status" SMALLINT DEFAULT 1,              -- Status field (1=active, 0=inactive)
    "XmoodID" UUID,
    "GlobalUID" UUID,
    CONSTRAINT "Nr_VocationalFields_pkey" PRIMARY KEY ("Nr_VocationalFieldID")
);

-- Create sequence for Nr_VocationalFields
CREATE SEQUENCE IF NOT EXISTS "Nr_VocationalFields_Nr_VocationalFieldID_seq"
    AS INTEGER
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE "Nr_VocationalFields" ALTER COLUMN "Nr_VocationalFieldID" SET DEFAULT nextval('"Nr_VocationalFields_Nr_VocationalFieldID_seq"');
ALTER SEQUENCE "Nr_VocationalFields_Nr_VocationalFieldID_seq" OWNED BY "Nr_VocationalFields"."Nr_VocationalFieldID";

-- Create indexes
CREATE INDEX IF NOT EXISTS "idx_Nr_VocationalFields_Code" ON "Nr_VocationalFields"("Code");

-- Create Nr_Specializations table (Reference table for specializations)
CREATE TABLE IF NOT EXISTS "Nr_Specializations" (
    "Nr_SpecializationID" INTEGER NOT NULL,
    "Name" CHARACTER VARYING(100),
    "Code" CHARACTER VARYING(10),
    "Description" TEXT,
    "SchoolID" CHARACTER VARYING(10),
    "Tenant" SMALLINT DEFAULT 1 NOT NULL,
    "Timestamp" BYTEA NOT NULL,
    "Status" SMALLINT DEFAULT 1,              -- Status field (1=active, 0=inactive)
    "XmoodID" UUID,
    "GlobalUID" UUID,
    CONSTRAINT "Nr_Specializations_pkey" PRIMARY KEY ("Nr_SpecializationID")
);

-- Create sequence for Nr_Specializations
CREATE SEQUENCE IF NOT EXISTS "Nr_Specializations_Nr_SpecializationID_seq"
    AS INTEGER
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE "Nr_Specializations" ALTER COLUMN "Nr_SpecializationID" SET DEFAULT nextval('"Nr_Specializations_Nr_SpecializationID_seq"');
ALTER SEQUENCE "Nr_Specializations_Nr_SpecializationID_seq" OWNED BY "Nr_Specializations"."Nr_SpecializationID";

-- Create indexes
CREATE INDEX IF NOT EXISTS "idx_Nr_Specializations_Code" ON "Nr_Specializations"("Code");

-- Create Nr_Groups table (Reference table for groups)
CREATE TABLE IF NOT EXISTS "Nr_Groups" (
    "Nr_GroupID" INTEGER NOT NULL,
    "GroupCode" CHARACTER VARYING(10),
    "GroupName" CHARACTER VARYING(100),
    "Description" TEXT,
    "SchoolID" CHARACTER VARYING(10),
    "Tenant" SMALLINT DEFAULT 1 NOT NULL,
    "Timestamp" BYTEA NOT NULL,
    "Status" SMALLINT DEFAULT 1,              -- Status field (1=active, 0=inactive)
    "XmoodID" UUID,
    "GlobalUID" UUID,
    CONSTRAINT "Nr_Groups_pkey" PRIMARY KEY ("Nr_GroupID")
);

-- Create sequence for Nr_Groups
CREATE SEQUENCE IF NOT EXISTS "Nr_Groups_Nr_GroupID_seq"
    AS INTEGER
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE "Nr_Groups" ALTER COLUMN "Nr_GroupID" SET DEFAULT nextval('"Nr_Groups_Nr_GroupID_seq"');
ALTER SEQUENCE "Nr_Groups_Nr_GroupID_seq" OWNED BY "Nr_Groups"."Nr_GroupID";

-- Create indexes
CREATE INDEX IF NOT EXISTS "idx_Nr_Groups_GroupCode" ON "Nr_Groups"("GroupCode");

-- Create Nr_GraduationYears table (Reference table for graduation years)
CREATE TABLE IF NOT EXISTS "Nr_GraduationYears" (
    "Nr_GraduationYearID" INTEGER NOT NULL,
    "Year" CHARACTER VARYING(10),
    "Description" CHARACTER VARYING(50),
    "SchoolID" CHARACTER VARYING(10),
    "Tenant" SMALLINT DEFAULT 1 NOT NULL,
    "Timestamp" BYTEA NOT NULL,
    "Status" SMALLINT DEFAULT 1,              -- Status field (1=active, 0=inactive)
    "XmoodID" UUID,
    "GlobalUID" UUID,
    CONSTRAINT "Nr_GraduationYears_pkey" PRIMARY KEY ("Nr_GraduationYearID")
);

-- Create sequence for Nr_GraduationYears
CREATE SEQUENCE IF NOT EXISTS "Nr_GraduationYears_Nr_GraduationYearID_seq"
    AS INTEGER
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE "Nr_GraduationYears" ALTER COLUMN "Nr_GraduationYearID" SET DEFAULT nextval('"Nr_GraduationYears_Nr_GraduationYearID_seq"');
ALTER SEQUENCE "Nr_GraduationYears_Nr_GraduationYearID_seq" OWNED BY "Nr_GraduationYears"."Nr_GraduationYearID";

-- Create indexes
CREATE INDEX IF NOT EXISTS "idx_Nr_GraduationYears_Year" ON "Nr_GraduationYears"("Year");

-- ============================================================================
-- Phase 2: Create Nr_Curricula (Master table - depends on school context)
-- ============================================================================

CREATE TABLE IF NOT EXISTS "Nr_Curricula" (
    "Nr_CurriculumID" INTEGER NOT NULL,
    "CurriculumName" CHARACTER VARYING(80),
    "Description" CHARACTER VARYING(255),
    "IsUpperSchool" SMALLINT,
    "ShortName" CHARACTER VARYING(20),
    "Remark" CHARACTER VARYING(255),
    "GradeSystem" CHARACTER VARYING(20),
    "FirstYear" INTEGER,
    "LastYear" INTEGER,
    "SchoolID" CHARACTER VARYING(10),         -- Added SchoolID for multi-school context
    "Tenant" SMALLINT DEFAULT 1 NOT NULL,
    "Timestamp" BYTEA NOT NULL,
    "Status" SMALLINT DEFAULT 1,              -- Status field instead of deletion
    "XmoodID" UUID,
    "GlobalUID" UUID,
    "IsActive" SMALLINT DEFAULT 1,
    CONSTRAINT "Nr_Curricula_pkey" PRIMARY KEY ("Nr_CurriculumID")
);

-- Create sequence for Nr_Curricula
CREATE SEQUENCE IF NOT EXISTS "Nr_Curricula_Nr_CurriculumID_seq"
    AS INTEGER
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE "Nr_Curricula" ALTER COLUMN "Nr_CurriculumID" SET DEFAULT nextval('"Nr_Curricula_Nr_CurriculumID_seq"');
ALTER SEQUENCE "Nr_Curricula_Nr_CurriculumID_seq" OWNED BY "Nr_Curricula"."Nr_CurriculumID";

-- Create indexes
CREATE INDEX IF NOT EXISTS "idx_Nr_Curricula_SchoolID" ON "Nr_Curricula"("SchoolID");
CREATE INDEX IF NOT EXISTS "idx_Nr_Curricula_IsActive" ON "Nr_Curricula"("IsActive");

COMMENT ON TABLE "Nr_Curricula" IS 'Master table for curricula - depends on school context';

-- ============================================================================
-- Phase 3: Create Nr_Teachers (Depends on Nr_Users)
-- ============================================================================

-- Note: Nr_Teachers table should already exist from previous migrations
-- If not, create it here with proper foreign key to Nr_Users

CREATE TABLE IF NOT EXISTS "Nr_Teachers" (
    "Nr_TeacherID" INTEGER NOT NULL,
    "Nr_UserID" INTEGER,                         -- Foreign Key to Nr_Users (for personal information)
    "TeacherCode" CHARACTER VARYING(5),          -- For code-based lookups (not primary reference)
    "SchoolID" CHARACTER VARYING(10),            -- School identifier for multi-school systems
    "StaffType" CHARACTER VARYING(20),           -- Type of staff (e.g., full-time, part-time, substitute)
    "DepartmentID" INTEGER,                      -- Department where teacher belongs
    "HireDate" DATE,                             -- Date when hired
    "TerminationDate" DATE,                      -- Date when employment ended (NULL if active)
    "Position" CHARACTER VARYING(50),            -- Employment position title
    "SalaryGrade" CHARACTER VARYING(10),         -- Salary grade level
    "ContractType" CHARACTER VARYING(20),        -- Contract type (permanent, temporary, etc.)
    "IsFullTime" SMALLINT DEFAULT 1,             -- 1=full-time, 0=part-time
    "MaxTeachingHours" SMALLINT,                 -- Maximum teaching hours allowed
    "Tenant" SMALLINT DEFAULT 1 NOT NULL,
    "Timestamp" BYTEA NOT NULL,
    "Status" SMALLINT DEFAULT 1,                 -- Status field (1=active, 0=inactive) instead of deletion
    "XmoodID" UUID,
    "GlobalUID" UUID,
    CONSTRAINT "Nr_Teachers_pkey" PRIMARY KEY ("Nr_TeacherID")
);

-- Create sequence for Nr_Teachers
CREATE SEQUENCE IF NOT EXISTS "Nr_Teachers_Nr_TeacherID_seq"
    AS INTEGER
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE "Nr_Teachers" ALTER COLUMN "Nr_TeacherID" SET DEFAULT nextval('"Nr_Teachers_Nr_TeacherID_seq"');
ALTER SEQUENCE "Nr_Teachers_Nr_TeacherID_seq" OWNED BY "Nr_Teachers"."Nr_TeacherID";

-- Create foreign key to Nr_Users (if Nr_Users table exists)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'Nr_Users') THEN
        ALTER TABLE "Nr_Teachers"
            DROP CONSTRAINT IF EXISTS "FK_Teachers_User";
        ALTER TABLE "Nr_Teachers"
            ADD CONSTRAINT "FK_Teachers_User"
            FOREIGN KEY ("Nr_UserID") REFERENCES "Nr_Users"("UserID");
    END IF;
END $$;

-- Create indexes
CREATE INDEX IF NOT EXISTS "idx_Nr_Teachers_Nr_UserID" ON "Nr_Teachers"("Nr_UserID");
CREATE INDEX IF NOT EXISTS "idx_Nr_Teachers_TeacherCode" ON "Nr_Teachers"("TeacherCode");
CREATE INDEX IF NOT EXISTS "idx_Nr_Teachers_SchoolID" ON "Nr_Teachers"("SchoolID");
CREATE INDEX IF NOT EXISTS "idx_Nr_Teachers_Status" ON "Nr_Teachers"("Status");

COMMENT ON TABLE "Nr_Teachers" IS 'Teacher administrative data - personal info in Nr_Users. Addresses teacher code reference issue.';

-- ============================================================================
-- Phase 4: Create Nr_Classes (Depends on multiple reference tables)
-- ============================================================================

CREATE TABLE IF NOT EXISTS "Nr_Classes" (
    "Nr_ClassID" INTEGER NOT NULL,
    "SchoolID" CHARACTER VARYING(10),
    "SchoolYearID" INTEGER,                   -- Foreign Key to Nr_SchoolYears table
    "SchoolSemesterID" INTEGER,               -- Foreign Key to Nr_SchoolSemesters table
    "Description" CHARACTER VARYING(150),
    "ShortName" CHARACTER VARYING(10),
    "SchoolCategoryID" INTEGER,               -- Foreign Key to Nr_SchoolCategories table
    "ClassLevel" CHARACTER VARYING(3),
    "ClassTeacherID" INTEGER,                 -- Foreign Key to Nr_Teachers table (Nr_TeacherID)
    "DeputyClassTeacherID" INTEGER,           -- Foreign Key to Nr_Teachers table (Nr_TeacherID)
    "ClassroomID" INTEGER,                    -- Foreign Key to Nr_Rooms table
    "MaxStudents" SMALLINT,
    "TeachingFormID" INTEGER,                 -- Foreign Key to Nr_TeachingForms table
    "ClassCategoryID" INTEGER,                -- Foreign Key to Nr_ClassCategories table
    "DifferentiationID" INTEGER,              -- Foreign Key to Nr_Differentiation table
    "DefaultCurriculumID" INTEGER,            -- Foreign Key to Nr_Curricula table
    "BlockGroupID" INTEGER,                   -- Foreign Key to Nr_BlockGroups table
    "RequirementBasis" CHARACTER VARYING(50),
    "BlockKey" CHARACTER VARYING(100),
    "BlockTypeID" INTEGER,                    -- Foreign Key to Nr_BlockTypes table
    "Remarks" CHARACTER VARYING(100),
    "DepartmentID" INTEGER,                   -- Foreign Key to Nr_Departments table
    "EducationPathID" INTEGER,                -- Foreign Key to Nr_EducationPaths table
    "SpecializationID" INTEGER,               -- Foreign Key to Nr_Specializations table
    "BranchID" INTEGER,                       -- Foreign Key to Nr_Branches table
    "CourseID" INTEGER,                       -- Foreign Key to Nr_Courses table
    "OfficialName" CHARACTER VARYING(30),
    "EthicsClass" SMALLINT DEFAULT 0,
    "SpecialFeature" CHARACTER VARYING(2),
    "BranchOfficeID" INTEGER,                 -- Foreign Key to Nr_BranchOffices table
    "ExplanationFeature" CHARACTER VARYING(2),
    "BlockWeeksCount" SMALLINT,
    "Statistics" SMALLINT DEFAULT 1,
    "ProfessionalFieldID" INTEGER,            -- Foreign Key to Nr_ProfessionalFields table
    "ProfessionID" INTEGER,                   -- Foreign Key to Nr_Professions table
    "LevelID" INTEGER,                        -- Foreign Key to Nr_Levels table
    "VocationalField2ID" INTEGER,             -- Foreign Key to Nr_VocationalFields table
    "IdentifierCode" CHARACTER VARYING(10),
    "SchoolPartID" INTEGER,                   -- Foreign Key to Nr_SchoolParts table
    "ClassTypeID" INTEGER,                    -- Foreign Key to Nr_ClassTypes table
    "QualificationID" INTEGER,                -- Foreign Key to Nr_Qualifications table
    "CrossCountryVocationalClasses" SMALLINT,
    "ApplicantClass" SMALLINT DEFAULT 0,
    "InTimetable" SMALLINT DEFAULT 0,
    "ClassTeacherHours" REAL,
    "ClassHours" REAL,
    "Timestamp" BYTEA NOT NULL,
    "UntisID" CHARACTER VARYING(50),
    "Tenant" SMALLINT DEFAULT 1 NOT NULL,
    "XmoodID" UUID,
    "GlobalUID" UUID,
    "GraduationClass" SMALLINT DEFAULT 0 NOT NULL,
    "Status" SMALLINT DEFAULT 1,              -- Status field instead of deletion
    CONSTRAINT "Nr_Classes_pkey" PRIMARY KEY ("Nr_ClassID")
);

-- Create sequence for Nr_Classes
CREATE SEQUENCE IF NOT EXISTS "Nr_Classes_Nr_ClassID_seq"
    AS INTEGER
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE "Nr_Classes" ALTER COLUMN "Nr_ClassID" SET DEFAULT nextval('"Nr_Classes_Nr_ClassID_seq"');
ALTER SEQUENCE "Nr_Classes_Nr_ClassID_seq" OWNED BY "Nr_Classes"."Nr_ClassID";

-- Create foreign key constraints
ALTER TABLE "Nr_Classes"
    DROP CONSTRAINT IF EXISTS "FK_Classes_SchoolYear";
ALTER TABLE "Nr_Classes"
    ADD CONSTRAINT "FK_Classes_SchoolYear"
    FOREIGN KEY ("SchoolYearID") REFERENCES "Nr_SchoolYears"("Nr_SchoolYearID");

ALTER TABLE "Nr_Classes"
    DROP CONSTRAINT IF EXISTS "FK_Classes_SchoolSemester";
ALTER TABLE "Nr_Classes"
    ADD CONSTRAINT "FK_Classes_SchoolSemester"
    FOREIGN KEY ("SchoolSemesterID") REFERENCES "Nr_SchoolSemesters"("Nr_SchoolSemesterID");

ALTER TABLE "Nr_Classes"
    DROP CONSTRAINT IF EXISTS "FK_Classes_SchoolCategory";
ALTER TABLE "Nr_Classes"
    ADD CONSTRAINT "FK_Classes_SchoolCategory"
    FOREIGN KEY ("SchoolCategoryID") REFERENCES "Nr_SchoolCategories"("Nr_SchoolCategoryID");

ALTER TABLE "Nr_Classes"
    DROP CONSTRAINT IF EXISTS "FK_Classes_ClassTeacher";
ALTER TABLE "Nr_Classes"
    ADD CONSTRAINT "FK_Classes_ClassTeacher"
    FOREIGN KEY ("ClassTeacherID") REFERENCES "Nr_Teachers"("Nr_TeacherID");

ALTER TABLE "Nr_Classes"
    DROP CONSTRAINT IF EXISTS "FK_Classes_DeputyClassTeacher";
ALTER TABLE "Nr_Classes"
    ADD CONSTRAINT "FK_Classes_DeputyClassTeacher"
    FOREIGN KEY ("DeputyClassTeacherID") REFERENCES "Nr_Teachers"("Nr_TeacherID");

ALTER TABLE "Nr_Classes"
    DROP CONSTRAINT IF EXISTS "FK_Classes_Classroom";
ALTER TABLE "Nr_Classes"
    ADD CONSTRAINT "FK_Classes_Classroom"
    FOREIGN KEY ("ClassroomID") REFERENCES "Nr_Rooms"("Nr_RoomID");

ALTER TABLE "Nr_Classes"
    DROP CONSTRAINT IF EXISTS "FK_Classes_Curriculum";
ALTER TABLE "Nr_Classes"
    ADD CONSTRAINT "FK_Classes_Curriculum"
    FOREIGN KEY ("DefaultCurriculumID") REFERENCES "Nr_Curricula"("Nr_CurriculumID");

ALTER TABLE "Nr_Classes"
    DROP CONSTRAINT IF EXISTS "FK_Classes_ProfessionalField";
ALTER TABLE "Nr_Classes"
    ADD CONSTRAINT "FK_Classes_ProfessionalField"
    FOREIGN KEY ("ProfessionalFieldID") REFERENCES "Nr_ProfessionalFields"("Nr_ProfessionalFieldID");

ALTER TABLE "Nr_Classes"
    DROP CONSTRAINT IF EXISTS "FK_Classes_Profession";
ALTER TABLE "Nr_Classes"
    ADD CONSTRAINT "FK_Classes_Profession"
    FOREIGN KEY ("ProfessionID") REFERENCES "Nr_Professions"("Nr_ProfessionID");

ALTER TABLE "Nr_Classes"
    DROP CONSTRAINT IF EXISTS "FK_Classes_Specialization";
ALTER TABLE "Nr_Classes"
    ADD CONSTRAINT "FK_Classes_Specialization"
    FOREIGN KEY ("SpecializationID") REFERENCES "Nr_Specializations"("Nr_SpecializationID");

ALTER TABLE "Nr_Classes"
    DROP CONSTRAINT IF EXISTS "FK_Classes_VocationalField2";
ALTER TABLE "Nr_Classes"
    ADD CONSTRAINT "FK_Classes_VocationalField2"
    FOREIGN KEY ("VocationalField2ID") REFERENCES "Nr_VocationalFields"("Nr_VocationalFieldID");

-- Create indexes
CREATE INDEX IF NOT EXISTS "idx_Nr_Classes_SchoolID" ON "Nr_Classes"("SchoolID");
CREATE INDEX IF NOT EXISTS "idx_Nr_Classes_SchoolYearID" ON "Nr_Classes"("SchoolYearID");
CREATE INDEX IF NOT EXISTS "idx_Nr_Classes_SchoolSemesterID" ON "Nr_Classes"("SchoolSemesterID");
CREATE INDEX IF NOT EXISTS "idx_Nr_Classes_ClassTeacherID" ON "Nr_Classes"("ClassTeacherID");
CREATE INDEX IF NOT EXISTS "idx_Nr_Classes_Status" ON "Nr_Classes"("Status");

COMMENT ON TABLE "Nr_Classes" IS 'Classes table with proper foreign key relationships. Addresses class and room reference issues.';

-- ============================================================================
-- Phase 5: Create Curriculum-Related Tables
-- ============================================================================

-- Create Nr_CurriculumRemarks (Depends on Nr_Curricula)
CREATE TABLE IF NOT EXISTS "Nr_CurriculumRemarks" (
    "Nr_CurriculumRemarkID" INTEGER NOT NULL,
    "Nr_CurriculumID" INTEGER,               -- Foreign Key to Nr_Curricula
    "Description" CHARACTER VARYING(30),
    "DescriptionPosition" SMALLINT,
    "Timestamp" BYTEA NOT NULL,
    "Tenant" SMALLINT DEFAULT 1 NOT NULL,
    "CharacterCount" SMALLINT,
    "Status" SMALLINT DEFAULT 1,              -- Status field instead of deletion
    CONSTRAINT "Nr_CurriculumRemarks_pkey" PRIMARY KEY ("Nr_CurriculumRemarkID")
);

-- Create sequence for Nr_CurriculumRemarks
CREATE SEQUENCE IF NOT EXISTS "Nr_CurriculumRemarks_Nr_CurriculumRemarkID_seq"
    AS INTEGER
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE "Nr_CurriculumRemarks" ALTER COLUMN "Nr_CurriculumRemarkID" SET DEFAULT nextval('"Nr_CurriculumRemarks_Nr_CurriculumRemarkID_seq"');
ALTER SEQUENCE "Nr_CurriculumRemarks_Nr_CurriculumRemarkID_seq" OWNED BY "Nr_CurriculumRemarks"."Nr_CurriculumRemarkID";

-- Create foreign key
ALTER TABLE "Nr_CurriculumRemarks"
    DROP CONSTRAINT IF EXISTS "FK_CurriculumRemarks_Curriculum";
ALTER TABLE "Nr_CurriculumRemarks"
    ADD CONSTRAINT "FK_CurriculumRemarks_Curriculum"
    FOREIGN KEY ("Nr_CurriculumID") REFERENCES "Nr_Curricula"("Nr_CurriculumID")
    ON DELETE CASCADE ON UPDATE CASCADE;

-- Create Nr_CurriculumSubjects (Depends on Nr_Curricula and Nr_Subjects)
CREATE TABLE IF NOT EXISTS "Nr_CurriculumSubjects" (
    "Nr_CurriculumSubjectID" INTEGER NOT NULL,
    "Nr_CurriculumID" INTEGER,                -- Foreign Key to Nr_Curricula
    "Nr_SubjectID" INTEGER,                   -- Foreign Key to Nr_Subjects
    "GONumber" SMALLINT,
    "TargetHours" DOUBLE PRECISION,
    "SubjectPosition" SMALLINT,
    "Factor" DOUBLE PRECISION,
    "CourseType" CHARACTER VARYING(5),
    "Tenant" SMALLINT DEFAULT 1 NOT NULL,
    "YearlyHours" SMALLINT,
    "Timestamp" BYTEA NOT NULL,
    "Status" SMALLINT DEFAULT 1,              -- Status field instead of deletion
    CONSTRAINT "Nr_CurriculumSubjects_pkey" PRIMARY KEY ("Nr_CurriculumSubjectID")
);

-- Create sequence for Nr_CurriculumSubjects
CREATE SEQUENCE IF NOT EXISTS "Nr_CurriculumSubjects_Nr_CurriculumSubjectID_seq"
    AS INTEGER
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE "Nr_CurriculumSubjects" ALTER COLUMN "Nr_CurriculumSubjectID" SET DEFAULT nextval('"Nr_CurriculumSubjects_Nr_CurriculumSubjectID_seq"');
ALTER SEQUENCE "Nr_CurriculumSubjects_Nr_CurriculumSubjectID_seq" OWNED BY "Nr_CurriculumSubjects"."Nr_CurriculumSubjectID";

-- Create foreign keys
ALTER TABLE "Nr_CurriculumSubjects"
    DROP CONSTRAINT IF EXISTS "FK_CurriculumSubjects_Curriculum";
ALTER TABLE "Nr_CurriculumSubjects"
    ADD CONSTRAINT "FK_CurriculumSubjects_Curriculum"
    FOREIGN KEY ("Nr_CurriculumID") REFERENCES "Nr_Curricula"("Nr_CurriculumID")
    ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "Nr_CurriculumSubjects"
    DROP CONSTRAINT IF EXISTS "FK_CurriculumSubjects_Subject";
ALTER TABLE "Nr_CurriculumSubjects"
    ADD CONSTRAINT "FK_CurriculumSubjects_Subject"
    FOREIGN KEY ("Nr_SubjectID") REFERENCES "Nr_Subjects"("Nr_SubjectID")
    ON DELETE CASCADE ON UPDATE CASCADE;

-- Create Nr_CurriculumEvents (Depends on multiple tables: Teachers, Classes, Subjects, Rooms)
CREATE TABLE IF NOT EXISTS "Nr_CurriculumEvents" (
    "Nr_CurriculumEventID" INTEGER NOT NULL,
    "LessonNumber" INTEGER,
    "PlanNumber" INTEGER,
    "TeacherID" INTEGER,                      -- Foreign Key to Nr_Teachers
    "ClassID" INTEGER,                        -- Foreign Key to Nr_Classes
    "Nr_SubjectID" INTEGER,                   -- Foreign Key to Nr_Subjects
    "Hours" SMALLINT,
    "GivenHours" DOUBLE PRECISION,
    "IsAssigned" SMALLINT,
    "CoupledNumber" INTEGER,
    "Nr_RoomID" INTEGER,                      -- Foreign Key to Nr_Rooms
    "Nr_HomeRoomID" INTEGER,                  -- Foreign Key to Nr_Rooms
    "Identifier" CHARACTER VARYING(5),
    "NumberOfStudents" SMALLINT,
    "BlockSize" SMALLINT,
    "RoomHours" SMALLINT,
    "TVN" CHARACTER VARYING(1),
    "Distribution" CHARACTER VARYING(10),
    "WeekSets1" INTEGER,
    "WeekSets2" INTEGER,
    "Fixed" SMALLINT,
    "Topic" CHARACTER VARYING(50),
    "IsCoupled" SMALLINT,
    "Timestamp" BYTEA NOT NULL,
    "Tenant" SMALLINT DEFAULT 1 NOT NULL,
    "Status" SMALLINT DEFAULT 1,              -- Status field instead of deletion
    CONSTRAINT "Nr_CurriculumEvents_pkey" PRIMARY KEY ("Nr_CurriculumEventID")
);

-- Create sequence for Nr_CurriculumEvents
CREATE SEQUENCE IF NOT EXISTS "Nr_CurriculumEvents_Nr_CurriculumEventID_seq"
    AS INTEGER
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE "Nr_CurriculumEvents" ALTER COLUMN "Nr_CurriculumEventID" SET DEFAULT nextval('"Nr_CurriculumEvents_Nr_CurriculumEventID_seq"');
ALTER SEQUENCE "Nr_CurriculumEvents_Nr_CurriculumEventID_seq" OWNED BY "Nr_CurriculumEvents"."Nr_CurriculumEventID";

-- Create foreign keys
ALTER TABLE "Nr_CurriculumEvents"
    DROP CONSTRAINT IF EXISTS "FK_CurriculumEvents_Teacher";
ALTER TABLE "Nr_CurriculumEvents"
    ADD CONSTRAINT "FK_CurriculumEvents_Teacher"
    FOREIGN KEY ("TeacherID") REFERENCES "Nr_Teachers"("Nr_TeacherID")
    ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE "Nr_CurriculumEvents"
    DROP CONSTRAINT IF EXISTS "FK_CurriculumEvents_Class";
ALTER TABLE "Nr_CurriculumEvents"
    ADD CONSTRAINT "FK_CurriculumEvents_Class"
    FOREIGN KEY ("ClassID") REFERENCES "Nr_Classes"("Nr_ClassID")
    ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE "Nr_CurriculumEvents"
    DROP CONSTRAINT IF EXISTS "FK_CurriculumEvents_Subject";
ALTER TABLE "Nr_CurriculumEvents"
    ADD CONSTRAINT "FK_CurriculumEvents_Subject"
    FOREIGN KEY ("Nr_SubjectID") REFERENCES "Nr_Subjects"("Nr_SubjectID")
    ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE "Nr_CurriculumEvents"
    DROP CONSTRAINT IF EXISTS "FK_CurriculumEvents_Room";
ALTER TABLE "Nr_CurriculumEvents"
    ADD CONSTRAINT "FK_CurriculumEvents_Room"
    FOREIGN KEY ("Nr_RoomID") REFERENCES "Nr_Rooms"("Nr_RoomID")
    ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE "Nr_CurriculumEvents"
    DROP CONSTRAINT IF EXISTS "FK_CurriculumEvents_HomeRoom";
ALTER TABLE "Nr_CurriculumEvents"
    ADD CONSTRAINT "FK_CurriculumEvents_HomeRoom"
    FOREIGN KEY ("Nr_HomeRoomID") REFERENCES "Nr_Rooms"("Nr_RoomID")
    ON DELETE SET NULL ON UPDATE CASCADE;

-- Note: Flyway automatically commits the transaction
