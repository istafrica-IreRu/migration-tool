# WinSchool Database Migration Guide - 3NF Normalization

## Overview

This document provides comprehensive SQL scripts and instructions to migrate data from the legacy WinSchool database tables to the new 3NF normalized schema. This migration addresses critical normalization issues identified in your normalization plan, particularly:

- **Semester reference issue**: Converting character-based semester values to proper foreign key relationships
- **Teacher code references**: Converting character codes to proper foreign key relationships
- **Class and room references**: Converting character codes to proper foreign key relationships
- **Elimination of transitive dependencies**: Proper separation of concerns across normalized tables
- **Referential integrity**: Establishing proper foreign key constraints across the normalized schema

## Pre-Migration Preparation

### 1. Create a Full Database Backup
```bash
pg_dump -U username -h hostname -p port -d database_name > backup_file.sql
```

### 2. Set Up the New Normalized Schema
Before running the migration scripts, ensure that all new normalized tables are created using the schema from `complete_normalized_schema.sql`. The migration scripts in this document assume that all target tables already exist with their proper foreign key constraints.

### 3. Test Environment Setup
It is strongly recommended to test these migration scripts in a non-production environment first:

1. Create a copy of your production database for testing
2. Apply the new normalized schema to the test database
3. Run the migration scripts on the test database
4. Validate data integrity and application functionality
5. Address any issues before applying to production

## Migration Order

Due to foreign key dependencies, tables must be migrated in a specific order:

1. **Reference Tables**: SchoolSemesters, Subjects, Teachers, Rooms, and other lookup tables
2. **Master Tables**: Curricula, Users, and other foundational tables
3. **Core Tables**: Classes, Students
4. **Detail Tables**: StudentSchoolInfo, StudentStatus, and related tables
5. **Curriculum Tables**: CurriculumSubjects, CurriculumEvents

## Migration Prerequisites

Before running the migration scripts, please ensure:

1. The new normalized tables are created using the schema from `complete_normalized_schema.sql`
2. You have a complete backup of your original database
3. You have sufficient privileges to insert data into the new tables
4. Foreign key constraints are temporarily disabled during migration if needed
5. You have tested the scripts in a non-production environment

## Special Migration Approach: Preserving Old IDs and Handling ALTERed Tables

This migration script follows a special approach where:
- **Old Primary Keys are Preserved**: The original IDs from legacy tables are maintained as the new normalized table IDs to preserve existing foreign key relationships
- **UPDATE vs INSERT Strategy**: For tables that have been ALTERed (like Nr_Groups), UPDATE statements are used to populate existing records. For completely new tables, INSERT statements are used.
- **Gradual Migration**: The approach allows for preserving relationships while migrating to the normalized structure.

For tables that have already been ALTERed (like Nr_Groups, Nr_Teachers), the scripts use UPDATE statements to preserve existing data and relationships. For new tables created from scratch, INSERT statements are used while ensuring that old IDs continue to reference the same logical records.

## Special Case: Modifying Existing Nr_Teachers Table

Since you mentioned that you already have an existing `Nr_Teachers` table that is referenced by other tables, we need to ALTER the existing table rather than drop and recreate it. Here's the approach for safely modifying the existing table:

```sql
-- Step 1: Add new columns that don't exist in the current table
ALTER TABLE public."Nr_Teachers" ADD COLUMN IF NOT EXISTS "Nr_TeacherID" integer;
ALTER TABLE public."Nr_Teachers" ADD COLUMN IF NOT EXISTS "Nr_UserID" integer;
ALTER TABLE public."Nr_Teachers" ADD COLUMN IF NOT EXISTS "TeacherCode" character varying(5);
ALTER TABLE public."Nr_Teachers" ADD COLUMN IF NOT EXISTS "StaffType" character varying(20);
ALTER TABLE public."Nr_Teachers" ADD COLUMN IF NOT EXISTS "DepartmentID" integer;
ALTER TABLE public."Nr_Teachers" ADD COLUMN IF NOT EXISTS "HireDate" date;
ALTER TABLE public."Nr_Teachers" ADD COLUMN IF NOT EXISTS "TerminationDate" date;
ALTER TABLE public."Nr_Teachers" ADD COLUMN IF NOT EXISTS "Position" character varying(50);
ALTER TABLE public."Nr_Teachers" ADD COLUMN IF NOT EXISTS "SalaryGrade" character varying(10);
ALTER TABLE public."Nr_Teachers" ADD COLUMN IF NOT EXISTS "ContractType" character varying(20);
ALTER TABLE public."Nr_Teachers" ADD COLUMN IF NOT EXISTS "IsFullTime" smallint DEFAULT 1;
ALTER TABLE public."Nr_Teachers" ADD COLUMN IF NOT EXISTS "MaxTeachingHours" smallint;
ALTER TABLE public."Nr_Teachers" ADD COLUMN IF NOT EXISTS "Tenant" smallint DEFAULT 1;
ALTER TABLE public."Nr_Teachers" ADD COLUMN IF NOT EXISTS "Timestamp" bytea;
ALTER TABLE public."Nr_Teachers" ADD COLUMN IF NOT EXISTS "Status" smallint DEFAULT 1;
ALTER TABLE public."Nr_Teachers" ADD COLUMN IF NOT EXISTS "XmoodID" uuid;

-- Step 2: Migrate existing data to new column structure
UPDATE public."Nr_Teachers"
SET
    "Nr_TeacherID" = "TeacherID",
    "Nr_UserID" = "UserID",
    "TeacherCode" = "Code",
    "SchoolID" = "SchoolID",
    "HireDate" = "LastModified",  -- Using LastModified as HireDate if no specific hire date exists
    "Position" = COALESCE("Position", "FirstName" || ' ' || "LastName"),  -- Creating position from available data
    "Tenant" = COALESCE("TenantID", 1),
    "Status" = 1;  -- Setting all existing records as active

-- Step 3: Make new columns NOT NULL where required
ALTER TABLE public."Nr_Teachers" ALTER COLUMN "Nr_TeacherID" SET NOT NULL;
ALTER TABLE public."Nr_Teachers" ALTER COLUMN "Tenant" SET NOT NULL;
ALTER TABLE public."Nr_Teachers" ALTER COLUMN "Status" SET DEFAULT 1;

-- Step 4: Add the new primary key constraint
-- First, if there's a default value for sequence, remove it
ALTER TABLE public."Nr_Teachers" ALTER COLUMN "TeacherID" DROP DEFAULT;

-- Step 5: Rename the primary key column and set up the new structure
ALTER TABLE public."Nr_Teachers" DROP CONSTRAINT IF EXISTS "Nr_Teachers_pkey";
ALTER TABLE public."Nr_Teachers" ADD CONSTRAINT "Nr_Teachers_pkey" PRIMARY KEY ("Nr_TeacherID");

-- Step 6: Add new foreign key constraints
ALTER TABLE public."Nr_Teachers" ADD CONSTRAINT "FK_Teachers_User"
    FOREIGN KEY ("Nr_UserID") REFERENCES public."Nr_Users"("UserID");
ALTER TABLE public."Nr_Teachers" ADD CONSTRAINT "FK_Teachers_School"
    FOREIGN KEY ("SchoolID") REFERENCES public."Nr_Schools"("SchoolID");

-- Step 7: If you want to remove old columns that are no longer needed (optional, do this carefully)
-- It's safer to keep them initially and remove them after confirming everything works
-- ALTER TABLE public."Nr_Teachers" DROP COLUMN "TeacherID", DROP COLUMN "UserID", DROP COLUMN "Code";

-- Step 8: Add an index on new foreign key columns for performance
CREATE INDEX IF NOT EXISTS "idx_teachers_userid" ON public."Nr_Teachers"("Nr_UserID");
CREATE INDEX IF NOT EXISTS "idx_teachers_schoolid" ON public."Nr_Teachers"("SchoolID");
```

**Important**: Before performing these operations:
1. Create a backup of your current `Nr_Teachers` table
2. Test these ALTER operations on a copy of your database first
3. Check which tables are referencing `Nr_Teachers` to understand the impact
4. Consider running these changes during a maintenance window

## Migration Scripts

### 1. Migration of Reference Tables

#### 1.1 Migrate SchoolSemesters to Nr_SchoolSemesters
```sql
-- Insert data from SchoolSemesters to Nr_SchoolSemesters
-- Handle the critical semester reference issue: SchoolSemester field should map to proper foreign key references
INSERT INTO public."Nr_SchoolSemesters" (
    "Nr_SchoolSemesterID", "SemesterCode", "Description", "StartDate", "EndDate",
    "SchoolID", "Tenant", "Timestamp", "Status", "XmoodID", "GlobalUID"
)
SELECT
    "ID" as "Nr_SchoolSemesterID",
    "SchoolSemester" as "SemesterCode",
    "SemesterText" as "Description",
    CASE
        WHEN "SchoolSemester" LIKE '%W%' OR "SchoolSemester" LIKE '%S%' OR LOWER("SemesterText") LIKE '%winter%'
        THEN MAKE_DATE(2000 + ("StudentNumber" % 100), 9, 1)
        WHEN "SchoolSemester" LIKE '%S%' OR LOWER("SemesterText") LIKE '%summer%' OR LOWER("SemesterText") LIKE '%spring%'
        THEN MAKE_DATE(2000 + ("StudentNumber" % 100), 2, 1)
        ELSE CURRENT_DATE
    END as "StartDate",
    CASE
        WHEN "SchoolSemester" LIKE '%W%' OR LOWER("SemesterText") LIKE '%winter%'
        THEN MAKE_DATE(2000 + ("StudentNumber" % 100), 1, 31)
        WHEN "SchoolSemester" LIKE '%S%' OR LOWER("SemesterText") LIKE '%summer%' OR LOWER("SemesterText") LIKE '%spring%'
        THEN MAKE_DATE(2000 + ("StudentNumber" % 100), 7, 31)
        ELSE CURRENT_DATE + INTERVAL '6 months'
    END + INTERVAL '1 year' as "EndDate",
    "SchoolID",
    "Tenant",
    "Timestamp",
    1 as "Status",
    gen_random_uuid() as "XmoodID",
    gen_random_uuid() as "GlobalUID"
FROM public."SchoolSemesters";
```

#### 1.2 Migrate SubjectsTable to Nr_Subjects
```sql
-- Insert data from SubjectsTable to Nr_Subjects
INSERT INTO public."Nr_Subjects" (
    "Nr_SubjectID", "SubjectCode", "SubjectName", "ShortName", "SubjectType", 
    "SubjectArea", "SubjectSubarea", "SubjectPosition", "SchoolID", 
    "Tenant", "Timestamp", "Status", "XmoodID", "GlobalUID"
)
SELECT 
    "ID" as "Nr_SubjectID",
    "SubjectCode" as "SubjectCode",
    "SubjectName" as "SubjectName",
    LEFT("SubjectName", 10) as "ShortName",
    COALESCE("SubjectArea", 'GEN') as "SubjectType",
    "SubjectArea" as "SubjectArea",
    "SubjectSubarea" as "SubjectSubarea",
    "SubjectPriority" as "SubjectPosition",
    "SchoolID",
    "Tenant",
    "Timestamp",
    1 as "Status",
    gen_random_uuid() as "XmoodID",
    gen_random_uuid() as "GlobalUID"
FROM public."SubjectsTable";

-- Note: Adjust field mapping based on actual SubjectsTable structure
```

#### 1.3 Update Existing Nr_Teachers Table Structure and Migrate Legacy Data
```sql
-- Now teachers,
INSERT INTO public."Nr_Teachers" (
    "Nr_TeacherID", "Nr_UserID", "TeacherCode", "SchoolID", "StaffType", 
    "DepartmentID", "HireDate", "TerminationDate", "Position", "SalaryGrade", 
    "ContractType", "IsFullTime", "MaxTeachingHours", "Tenant", 
    "Timestamp", "Status", "XmoodID", "GlobalUID"
)
SELECT 
    t."ID" AS "Nr_TeacherID",                    -- Preserve the old Teacher ID
    u."UserID" AS "Nr_UserID",                   -- Reference the UserID from Nr_Users
    t."Code" AS "TeacherCode",                   -- Map from Teachers table
    t."SchoolID",                                -- Map from Teachers table
    t."Category" AS "StaffType",                 -- Map Category → StaffType
    NULL AS "DepartmentID",                      -- No direct mapping; consider joining a departments ref table later
    t."EmploymentStart" AS "HireDate",           -- Map from Teachers
    t."EmploymentEnd" AS "TerminationDate",      -- Map from Teachers
    t."Position",                                -- Map from Teachers
    t."SalaryLevel" AS "SalaryGrade",            -- Map from Teachers
    t."EmploymentType" AS "ContractType",        -- Map from Teachers
    CASE                                          -- Derive IsFullTime flag
        WHEN t."EmploymentType" IN ('FT', 'FULLTIME', 'VZ', 'VOLLZEIT') THEN 1
        WHEN t."EmploymentType" IN ('PT', 'PARTTIME', 'TZ', 'TEILZEIT') THEN 0
        ELSE 1  -- default to full-time if unknown
    END AS "IsFullTime",
    t."RegularHours" AS "MaxTeachingHours",      -- Map from Teachers
    t."Tenant",
    t."Timestamp",
    1 AS "Status",                               -- 1 = active (adjust if enum differs)
    COALESCE(t."XmoodID", gen_random_uuid()) AS "XmoodID",
    COALESCE(t."GlobalUID", gen_random_uuid()) AS "GlobalUID"
FROM public."Teachers" t
JOIN public."Nr_Users" u ON t."ID" = u."UserID"
WHERE t."ID" NOT IN (SELECT "Nr_TeacherID" FROM public."Nr_Teachers");
```




#### 1.4 Migrate Rooms data if exists
```sql
-- If there's a Rooms table, migrate to Nr_Rooms
-- This is a template - adjust based on actual table structure
INSERT INTO public."Nr_Rooms" (
    "Nr_RoomID", "RoomNumber", "RoomName", "RoomType", "Capacity", 
    "SchoolID", "Building", "Floor", "Tenant", "Timestamp", 
    "Status", "XmoodID", "GlobalUID"
)
SELECT 
    "ID" as "Nr_RoomID",
    "RoomNumber" as "RoomNumber",  -- Assuming UntisID or similar becomes RoomNumber
    "Description" as "RoomName",   -- Assuming description becomes RoomName
    "RoomType" as "RoomType",      -- Assuming type classification exists
    "Capacity" as "Capacity",
    "SchoolID",
    "Building" as "Building",
    "Floor" as "Floor",
    "Tenant",
    "Timestamp",
    1 as "Status",
    "XmoodID",
    "GlobalUID"
FROM public."UntisRoom";  -- Assuming UntisRoom contains room data
-- Note: Adjust table name and field mapping based on actual structure
```

#### 1.5 Migrate School Years
```sql
-- Insert School Years (derive from existing date fields)
INSERT INTO public."Nr_SchoolYears" (
    "Nr_SchoolYearID", "YearCode", "Description", "StartDate", "EndDate", 
    "SchoolID", "Tenant", "Timestamp", "Status", "XmoodID", "GlobalUID"
)
SELECT DISTINCT
    ROW_NUMBER() OVER (ORDER BY "SchoolYear") as "Nr_SchoolYearID",
    "SchoolYear" as "YearCode",
    CONCAT('School Year ', "SchoolYear") as "Description",
    -- Create approximate start/end dates based on school year
    CASE 
        WHEN "SchoolYear" IS NOT NULL AND LENGTH("SchoolYear") = 2 
        THEN CONCAT('20', "SchoolYear", '-08-01')::date
        ELSE CURRENT_DATE
    END as "StartDate",
    CASE 
        WHEN "SchoolYear" IS NOT NULL AND LENGTH("SchoolYear") = 2 
        THEN CONCAT('20', "SchoolYear", '-07-31')::date + INTERVAL '1 year'
        ELSE CURRENT_DATE + INTERVAL '1 year'
    END as "EndDate",
    "SchoolID",
    "Tenant",
    "Timestamp",
    1 as "Status",
    "XmoodID",
    "GlobalUID"
FROM public."Students"
WHERE "SchoolYear" IS NOT NULL;


#### 1.6 Migrate Reference Tables (SchoolCategories, SchoolTypes, etc.)

-- For tables that were ALTERed instead of created new, we would use UPDATE statements
-- But for new reference tables like SchoolCategories, SchoolTypes, etc., we INSERT as before
-- since these are lookup/reference tables that don't have existing records to update

-- Create School Categories (from SchoolCategory field)
INSERT INTO public."Nr_SchoolCategories" (
    "Nr_SchoolCategoryID", "Name", "Code", "Description",
    "SchoolID", "Tenant", "Timestamp", "Status", "XmoodID", "GlobalUID"
)
SELECT DISTINCT
    "SchoolCategory" as "Nr_SchoolCategoryID",  -- Use the actual value as ID to preserve relationships
    "SchoolCategory" as "Name",
    "SchoolCategory" as "Code",
    CONCAT('Category: ', "SchoolCategory") as "Description",
    "SchoolID",
    "Tenant",
    "Timestamp",
    1 as "Status",
    "XmoodID",
    "GlobalUID"
FROM public."Students"
WHERE "SchoolCategory" IS NOT NULL AND "SchoolCategory" != '';

-- Create School Types (from SchoolType field)
INSERT INTO public."Nr_SchoolTypes" (
    "Nr_SchoolTypeID", "Name", "Code", "Description",
    "SchoolID", "Tenant", "Timestamp", "Status", "XmoodID", "GlobalUID"
)
SELECT DISTINCT
    "SchoolType" as "Nr_SchoolTypeID",  -- Using the field value as ID to preserve relationships
    "SchoolTypeText" as "Name",
    "SchoolType"::text as "Code",
    CONCAT('Type: ', "SchoolTypeText") as "Description",
    "SchoolID",
    "Tenant",
    "Timestamp",
    1 as "Status",
    "XmoodID",
    "GlobalUID"
FROM public."Students"
WHERE "SchoolType" IS NOT NULL;

-- Create Professions
INSERT INTO public."Nr_Professions" (
    "Nr_ProfessionID", "Name", "Code", "Description",
    "SchoolID", "Tenant", "Timestamp", "Status", "XmoodID", "GlobalUID"
)
SELECT DISTINCT
    "Profession" as "Nr_ProfessionID", -- Use the actual value as ID to preserve relationships
    "Profession" as "Name",
    LEFT("Profession", 10) as "Code",
    CONCAT('Profession: ', "Profession") as "Description",
    "SchoolID",
    "Tenant",
    "Timestamp",
    1 as "Status",
    "XmoodID",
    "GlobalUID"
FROM public."Students"
WHERE "Profession" IS NOT NULL AND "Profession" != '';

-- Create Professional Fields
INSERT INTO public."Nr_ProfessionalFields" (
    "Nr_ProfessionalFieldID", "Name", "Code", "Description",
    "SchoolID", "Tenant", "Timestamp", "Status", "XmoodID", "GlobalUID"
)
SELECT DISTINCT
    "ProfessionalField" as "Nr_ProfessionalFieldID", -- Use the actual value as ID to preserve relationships
    "ProfessionalField" as "Name",
    "ProfessionalField" as "Code",
    CONCAT('Professional Field: ', "ProfessionalField") as "Description",
    "SchoolID",
    "Tenant",
    "Timestamp",
    1 as "Status",
    "XmoodID",
    "GlobalUID"
FROM public."Students"
WHERE "ProfessionalField" IS NOT NULL AND "ProfessionalField" != '';

-- Create Vocational Fields
INSERT INTO public."Nr_VocationalFields" (
    "Nr_VocationalFieldID", "Name", "Code", "Description",
    "SchoolID", "Tenant", "Timestamp", "Status", "XmoodID", "GlobalUID"
)
SELECT DISTINCT
    "VocationalField2" as "Nr_VocationalFieldID", -- Use the actual value as ID to preserve relationships
    "VocationalField2" as "Name",
    "VocationalField2" as "Code",
    CONCAT('Vocational Field: ', "VocationalField2") as "Description",
    "SchoolID",
    "Tenant",
    "Timestamp",
    1 as "Status",
    "XmoodID",
    "GlobalUID"
FROM public."Students"
WHERE "VocationalField2" IS NOT NULL AND "VocationalField2" != '';

-- Create Specializations
INSERT INTO public."Nr_Specializations" (
    "Nr_SpecializationID", "Name", "Code", "Description",
    "SchoolID", "Tenant", "Timestamp", "Status", "XmoodID", "GlobalUID"
)
SELECT DISTINCT
    "Specialization" as "Nr_SpecializationID",  -- Use the actual value as ID to preserve relationships
    "Specialization" as "Name",
    "Specialization" as "Code",
    CONCAT('Specialization: ', "Specialization") as "Description",
    "SchoolID",
    "Tenant",
    "Timestamp",
    1 as "Status",
    "XmoodID",
    "GlobalUID"
FROM public."Students"
WHERE "Specialization" IS NOT NULL AND "Specialization" != '';

-- For Nr_Groups table: UPDATE if it was ALTERed, or INSERT if it's new
-- Assuming you ALTERed the existing Nr_Groups table, use UPDATE to preserve old IDs
UPDATE public."Nr_Groups"
SET
    "Nr_GroupID" = "ID",  -- Preserve the old ID
    "GroupCode" = COALESCE("GroupCode", "Code", "GroupName"),  -- Map from existing fields
    "GroupName" = COALESCE("GroupName", "Name", "Description", CONCAT('Group ', "ID")),  -- Map from existing fields
    "Description" = COALESCE("Description", "Remark", CONCAT('Description for Group ', "ID")),  -- Map from existing fields
    "SchoolID" = COALESCE("SchoolID", 'DEFAULT'),  -- Map from existing fields
    "Tenant" = COALESCE("Tenant", 1),  -- Map from existing fields
    "Timestamp" = COALESCE("Timestamp", E'\\x8000000000000000'::bytea),  -- Set default timestamp
    "Status" = COALESCE("Status", 1)  -- Set as active
WHERE "ID" IS NOT NULL;

-- If there are any groups that need to be inserted (from legacy Groups that weren't in Nr_Groups),
-- you might need to INSERT them based on your Students table or other source data
INSERT INTO public."Nr_Groups" (
    "Nr_GroupID", "GroupCode", "GroupName", "Description",
    "SchoolID", "Tenant", "Timestamp", "Status", "XmoodID", "GlobalUID"
)
SELECT DISTINCT
    "Group" as "Nr_GroupID",  -- Use the group code/value as the ID to preserve relationships
    "Group" as "GroupCode",
    CONCAT('Group ', "Group") as "GroupName",
    CONCAT('Group: ', "Group") as "Description",
    "SchoolID",
    "Tenant",
    "Timestamp",
    1 as "Status",
    "XmoodID",
    "GlobalUID"
FROM public."Students"
WHERE "Group" IS NOT NULL
    AND "Group" != ''
    AND "Group" NOT IN (SELECT "Nr_GroupID" FROM public."Nr_Groups");  -- Only insert if not already exists

-- Create Graduation Years
INSERT INTO public."Nr_GraduationYears" (
    "Nr_GraduationYearID", "Year", "Description",
    "SchoolID", "Tenant", "Timestamp", "Status", "XmoodID", "GlobalUID"
)
SELECT DISTINCT
    "GraduationYear" as "Nr_GraduationYearID",  -- Use the actual value as ID to preserve relationships
    "GraduationYear" as "Year",
    CONCAT('Graduation Year ', "GraduationYear") as "Description",
    "SchoolID",
    "Tenant",
    "Timestamp",
    1 as "Status",
    "XmoodID",
    "GlobalUID"
FROM public."Students"
WHERE "GraduationYear" IS NOT NULL AND "GraduationYear" != '';
```

### 2. Migration of Core Academic Tables

#### 2.1 Migrate Classes to Nr_Classes
```sql
-- For Nr_Classes table: UPDATE if it was ALTERed, or INSERT if it's new
-- Assuming you want to preserve the old IDs from the legacy Classes table

-- If Nr_Classes was ALTERed from an existing table, use this UPDATE approach:
UPDATE public."Nr_Classes"
SET
    "Nr_ClassID" = "ID",  -- Preserve the old ID
    "OriginalID" = "ID",  -- Keep reference to original
    "SchoolID" = "SchoolID",
    "SchoolYearID" = (SELECT "Nr_SchoolYearID" FROM public."Nr_SchoolYears" WHERE "YearCode" = nc."SchoolYear"),  -- Map from legacy data
    "SchoolSemesterID" = (SELECT "Nr_SchoolSemesterID" FROM public."Nr_SchoolSemesters" WHERE "SemesterCode" = nc."SchoolSemester"),  -- Map from legacy data
    "Description" = "Description",
    "ShortName" = "ShortName",
    "SchoolCategoryID" = (SELECT "Nr_SchoolCategoryID" FROM public."Nr_SchoolCategories" WHERE "Code" = nc."SchoolCategory"),
    "ClassLevel" = "ClassLevel",
    "ClassTeacherID" = (SELECT "Nr_TeacherID" FROM public."Nr_Teachers" WHERE "TeacherCode" = nc."ClassTeacher"),  -- Map from legacy teacher code
    "DeputyClassTeacherID" = (SELECT "Nr_TeacherID" FROM public."Nr_Teachers" WHERE "TeacherCode" = nc."DeputyClassTeacher"),  -- Map from legacy teacher code
    "ClassroomID" = (SELECT "Nr_RoomID" FROM public."Nr_Rooms" WHERE "RoomNumber" = nc."Classroom" OR "RoomName" = nc."Classroom"),
    "MaxStudents" = "MaxStudents",
    -- Map other fields as needed...
    "DefaultCurriculumID" = "DefaultCurriculum",
    "SpecializationID" = (SELECT "Nr_SpecializationID" FROM public."Nr_Specializations" WHERE "Code" = nc."Specialization" OR "Name" = nc."Specialization"),
    "ProfessionID" = (SELECT "Nr_ProfessionID" FROM public."Nr_Professions" WHERE "Code" = nc."Profession" OR "Name" = nc."Profession"),
    "ProfessionalFieldID" = (SELECT "Nr_ProfessionalFieldID" FROM public."Nr_ProfessionalFields" WHERE "Code" = nc."ProfessionalField" OR "Name" = nc."ProfessionalField"),
    "VocationalField2ID" = (SELECT "Nr_VocationalFieldID" FROM public."Nr_VocationalFields" WHERE "Code" = nc."VocationalField2" OR "Name" = nc."VocationalField2"),
    "RequirementBasis" = "RequirementBasis",
    "BlockKey" = "BlockKey",
    "OfficialName" = "OfficialName",
    "EthicsClass" = "EthicsClass",
    "SpecialFeature" = "SpecialFeature",
    "ExplanationFeature" = "ExplanationFeature",
    "BlockWeeksCount" = "BlockWeeksCount",
    "Statistics" = "Statistics",
    "IdentifierCode" = "IdentifierCode",
    "CourseID" = "Course",
    "LevelID" = "Level",
    "ClassHours" = "ClassHours",
    "ClassTeacherHours" = "ClassTeacherHours",
    "UntisID" = "UntisID",
    "Tenant" = "Tenant",
    "XmoodID" = "XmoodID",
    "GlobalUID" = "GlobalUID",
    "GraduationClass" = "GraduationClass",
    "Status" = 1
FROM public."Classes" nc  -- Using alias for the new/normalized classes table
WHERE public."Nr_Classes"."ID" = nc."ID";  -- Match based on old ID

-- If you need to insert classes that weren't already in Nr_Classes, use this:
INSERT INTO public."Nr_Classes" (
    "Nr_ClassID", "OriginalID", "SchoolID", "SchoolYearID", "SchoolSemesterID",
    "Description", "ShortName", "SchoolCategoryID", "ClassLevel",
    "ClassTeacherID", "DeputyClassTeacherID", "ClassroomID", "MaxStudents",
    "TeachingFormID", "ClassCategoryID", "DifferentiationID", "DefaultCurriculumID",
    "BlockGroupID", "RequirementBasis", "BlockKey", "BlockTypeID", "Remarks",
    "DepartmentID", "EducationPathID", "SpecializationID", "BranchID",
    "CourseID", "OfficialName", "EthicsClass", "SpecialFeature",
    "BranchOfficeID", "ExplanationFeature", "BlockWeeksCount", "Statistics",
    "ProfessionalFieldID", "ProfessionID", "LevelID", "VocationalField2ID",
    "IdentifierCode", "SchoolPartID", "ClassTypeID", "QualificationID",
    "CrossCountryVocationalClasses", "ApplicantClass", "InTimetable",
    "ClassTeacherHours", "ClassHours", "Timestamp", "UntisID", "Tenant",
    "XmoodID", "GlobalUID", "GraduationClass", "Status"
)
SELECT
    c."ID" as "Nr_ClassID",  -- Preserve the old ID
    c."ID" as "OriginalID",
    c."SchoolID",
    -- Map SchoolYear to SchoolYearID (needs lookup)
    (SELECT "Nr_SchoolYearID" FROM public."Nr_SchoolYears" WHERE "YearCode" = c."SchoolYear") as "SchoolYearID",
    -- Map SchoolSemester to SchoolSemesterID (needs lookup) - CRITICAL SEMESTER ISSUE
    (SELECT "Nr_SchoolSemesterID" FROM public."Nr_SchoolSemesters" WHERE "SemesterCode" = c."SchoolSemester") as "SchoolSemesterID",
    c."Description",
    c."ShortName",
    -- Map SchoolCategory to SchoolCategoryID (needs lookup)
    (SELECT "Nr_SchoolCategoryID" FROM public."Nr_SchoolCategories" WHERE "Code" = c."SchoolCategory") as "SchoolCategoryID",
    c."ClassLevel",
    -- SPECIAL CASE: Map ClassTeacher (code string) to ClassTeacherID (foreign key) - CRITICAL TEACHER CODE ISSUE
    (SELECT "Nr_TeacherID" FROM public."Nr_Teachers" WHERE "TeacherCode" = c."ClassTeacher") as "ClassTeacherID",
    -- SPECIAL CASE: Map DeputyClassTeacher (code string) to DeputyClassTeacherID (foreign key) - CRITICAL TEACHER CODE ISSUE
    (SELECT "Nr_TeacherID" FROM public."Nr_Teachers" WHERE "TeacherCode" = c."DeputyClassTeacher") as "DeputyClassTeacherID",
    -- Map Classroom (code string) to ClassroomID (foreign key) - CLASS REFERENCE ISSUE
    (SELECT "Nr_RoomID" FROM public."Nr_Rooms" WHERE "RoomNumber" = c."Classroom" OR "RoomName" = c."Classroom") as "ClassroomID",
    c."MaxStudents",
    -- Map TeachingForm to TeachingFormID (needs lookup) - CREATE MAPPING IF NEEDED
    NULL as "TeachingFormID",  -- Need to implement if reference table exists
    -- Map ClassCategory to ClassCategoryID (needs lookup) - CREATE MAPPING IF NEEDED
    NULL as "ClassCategoryID",  -- Need to implement if reference table exists
    -- Map Differentiation to DifferentiationID (needs lookup) - CREATE MAPPING IF NEEDED
    NULL as "DifferentiationID",  -- Need to implement if reference table exists
    c."DefaultCurriculum" as "DefaultCurriculumID",
    -- Map BlockGroup to BlockGroupID (needs lookup) - CREATE MAPPING IF NEEDED
    NULL as "BlockGroupID",  -- Need to implement if reference table exists
    c."RequirementBasis",
    c."BlockKey",
    -- Map BlockType to BlockTypeID (needs lookup) - CREATE MAPPING IF NEEDED
    NULL as "BlockTypeID",  -- Need to implement if reference table exists
    c."Remarks",
    -- Map Department to DepartmentID (needs lookup) - CREATE MAPPING IF NEEDED
    NULL as "DepartmentID",  -- Need to implement if reference table exists
    -- Map EducationPath to EducationPathID (needs lookup) - CREATE MAPPING IF NEEDED
    NULL as "EducationPathID",  -- Need to implement if reference table exists
    -- Map Specialization to SpecializationID (needs lookup)
    (SELECT "Nr_SpecializationID" FROM public."Nr_Specializations" WHERE "Code" = c."Specialization" OR "Name" = c."Specialization") as "SpecializationID",
    -- Map Branch to BranchID (needs lookup) - CREATE MAPPING IF NEEDED
    NULL as "BranchID",  -- Need to implement if reference table exists
    c."Course" as "CourseID",
    c."OfficialName",
    c."EthicsClass",
    c."SpecialFeature",
    -- Map BranchOffice to BranchOfficeID (needs lookup) - CREATE MAPPING IF NEEDED
    NULL as "BranchOfficeID",  -- Need to implement if reference table exists
    c."ExplanationFeature",
    c."BlockWeeksCount",
    c."Statistics",
    -- Map ProfessionalField to ProfessionalFieldID (needs lookup)
    (SELECT "Nr_ProfessionalFieldID" FROM public."Nr_ProfessionalFields" WHERE "Code" = c."ProfessionalField" OR "Name" = c."ProfessionalField") as "ProfessionalFieldID",
    -- Map Profession to ProfessionID (needs lookup)
    (SELECT "Nr_ProfessionID" FROM public."Nr_Professions" WHERE "Code" = c."Profession" OR "Name" = c."Profession") as "ProfessionID",
    c."Level" as "LevelID",  -- Store Level as LevelID
    -- Map VocationalField2 to VocationalField2ID (needs lookup)
    (SELECT "Nr_VocationalFieldID" FROM public."Nr_VocationalFields" WHERE "Code" = c."VocationalField2" OR "Name" = c."VocationalField2") as "VocationalField2ID",
    c."IdentifierCode",
    -- Map SchoolPart to SchoolPartID (needs lookup) - CREATE MAPPING IF NEEDED
    NULL as "SchoolPartID",  -- Need to implement if reference table exists
    -- Map ClassType to ClassTypeID (needs lookup) - CREATE MAPPING IF NEEDED
    NULL as "ClassTypeID",  -- Need to implement if reference table exists
    -- Map Qualification to QualificationID (needs lookup) - CREATE MAPPING IF NEEDED
    NULL as "QualificationID",  -- Need to implement if reference table exists
    c."CrossCountryVocationalClasses",
    c."ApplicantClass",
    c."InTimetable",
    c."ClassTeacherHours",
    c."ClassHours",
    c."Timestamp",
    c."UntisID",
    c."Tenant",
    c."XmoodID",
    c."GlobalUID",
    c."GraduationClass",
    1 as "Status"  -- Assuming all classes are active
FROM public."Classes" c
WHERE c."ID" NOT IN (SELECT "Nr_ClassID" FROM public."Nr_Classes");  -- Only insert if not already exists
```

#### 2.2 Create Core Users Table Entries
```sql
-- Create user entries for all students based on their personal information
-- Preserve the old student IDs as the new User IDs
INSERT INTO public."Nr_Users" (
    "UserID", "FirstName", "LastName", "BirthDate", "Gender",
    "NationalityID", "Email", "Phone", "Mobile", "PhotoFile",
    "Address", "City", "PostalCode", "Country", "TenantID",
    "GlobalUID", "LastModified"
)
SELECT
    "ID" as "UserID",  -- Using student ID as user ID (preserving old ID)
    "FirstName",
    "Name" as "LastName",
    "BirthDate",
    "Gender",
    -- Map Country to NationalityID (needs lookup)
    NULL as "NationalityID",  -- Need to implement nationality mapping
    "Email",
    "Phone",
    "Mobile",
    "PhotoFile",
    "Street" as "Address",
    "Residence" as "City",
    "PostalCode",
    "Country",
    "Tenant" as "TenantID",
    "GlobalUID",
    CURRENT_TIMESTAMP as "LastModified"
FROM public."Students";
```

#### 2.3 Migrate Students to Nr_Students
```sql
-- Insert core student information to Nr_Students, preserving old IDs
INSERT INTO public."Nr_Students" (
    "Nr_StudentID", "Nr_UserID", "YearOfArrival", "Country",
    "OfAge", "FinancialAid", "Disability", "EducationPath",
    "IdentifierCode", "Tenant", "Timestamp"
)
SELECT
    "ID" as "Nr_StudentID",  -- Preserve the old student ID
    "ID" as "Nr_UserID",    -- Using the same ID since we created user records with that ID
    "YearOfArrival",
    "Country",
    "OfAge",
    "FinancialAid",
    "Disability",
    "EducationPath",
    "IdentifierCode",
    "Tenant",
    "Timestamp"
FROM public."Students";
```

#### 2.4 Migrate Student School Information to Nr_StudentSchoolInfo
```sql
-- Insert academic period information to Nr_StudentSchoolInfo, preserving relationships
-- Since student IDs are preserved, the foreign key relationships remain intact

INSERT INTO public."Nr_StudentSchoolInfo" (
    "Nr_SchoolInfoID", "Nr_StudentID", "SchoolYearID", "SchoolSemesterID",
    "ClassID", "SchoolSemesterNumber", "ProfessionID", "CurriculumID",
    "CurriculumName", "Branch", "Level", "SchoolCategoryID", "SchoolTypeID",
    "SchoolTypeText", "SchoolYearCode", "EntryDate", "GraduationYearID",
    "Status", "TransferDate", "CareerStatus", "SchoolDataStatus",
    "EducationStatus", "FormSuffix", "DismissalDate", "Reason",
    "PartnerSchool", "PromotionEligibility", "ApprovedUntil",
    "DeviationFromStandardTime", "Repeater", "RepetitionReason",
    "FreeRepeater", "CompanyLock", "RequirementBasis",
    "AdditionalRequirementBasis", "SecondLanguageNew", "AdditionalLessons",
    "EmploymentContract", "LastExam", "EntryTrainingSemester", "APOCode",
    "ProfessionalFieldID", "VocationalField2ID", "SpecializationID",
    "GroupID", "TutorID", "MentorID", "ResponsibleTrainerID", "IsActive",
    "Timestamp"
)
SELECT
    -- Generate a unique ID for school info records (these are new records)
    (ROW_NUMBER() OVER (ORDER BY s."ID")) + 100000 as "Nr_SchoolInfoID",
    s."ID" as "Nr_StudentID",  -- Preserve the original student ID
    -- Map SchoolYear to SchoolYearID - CRITICAL SCHOOL YEAR ISSUE
    (SELECT "Nr_SchoolYearID" FROM public."Nr_SchoolYears" WHERE "YearCode" = s."SchoolYear") as "SchoolYearID",
    -- Map SchoolSemester to SchoolSemesterID - CRITICAL SEMESTER ISSUE (addresses the main concern in the normalization plan)
    (SELECT "Nr_SchoolSemesterID" FROM public."Nr_SchoolSemesters" WHERE "SemesterCode" = s."SchoolSemester") as "SchoolSemesterID",
    -- Map Class (code string) to ClassID (foreign key) - CRITICAL CLASS REFERENCE ISSUE
    (SELECT "Nr_ClassID" FROM public."Nr_Classes" WHERE
        "ShortName" = s."Class" OR "Description" = s."Class" OR "OriginalID" =
        (SELECT "ID" FROM public."Classes" WHERE "ShortName" = s."Class" OR "Description" = s."Class" LIMIT 1)
    ) as "ClassID",
    s."SchoolSemesterNumber",
    -- Map Profession to ProfessionID
    (SELECT "Nr_ProfessionID" FROM public."Nr_Professions" WHERE "Code" = s."Profession" OR "Name" = s."Profession") as "ProfessionID",
    s."Curriculum" as "CurriculumID",
    s."CurriculumName",
    s."Branch",
    s."Level",
    -- Map SchoolCategory to SchoolCategoryID
    (SELECT "Nr_SchoolCategoryID" FROM public."Nr_SchoolCategories" WHERE "Code" = s."SchoolCategory") as "SchoolCategoryID",
    s."SchoolType" as "SchoolTypeID",
    s."SchoolTypeText",
    s."SchoolYearCode",
    s."EntryDate",
    -- Map GraduationYear to GraduationYearID
    (SELECT "Nr_GraduationYearID" FROM public."Nr_GraduationYears" WHERE "Year" = s."GraduationYear") as "GraduationYearID",
    s."Status",
    s."TransferDate",
    s."CareerStatus",
    s."SchoolDataStatus",
    s."EducationStatus",
    s."FormSuffix",
    s."DismissalDate",
    s."Reason",
    s."PartnerSchool",
    s."PromotionEligibility",
    s."ApprovedUntil",
    s."DeviationFromStandardTime",
    s."Repeater",
    s."RepetitionReason",
    s."FreeRepeater",
    s."CompanyLock",
    s."RequirementBasis",
    s."AdditionalRequirementBasis",
    s."SecondLanguageNew",
    s."AdditionalLessons",
    s."EmploymentContract",
    s."LastExam",
    s."EntryTrainingSemester",
    s."APOCode",
    -- Map ProfessionalField to ProfessionalFieldID
    (SELECT "Nr_ProfessionalFieldID" FROM public."Nr_ProfessionalFields" WHERE "Code" = s."ProfessionalField" OR "Name" = s."ProfessionalField") as "ProfessionalFieldID",
    -- Map VocationalField2 to VocationalField2ID
    (SELECT "Nr_VocationalFieldID" FROM public."Nr_VocationalFields" WHERE "Code" = s."VocationalField2" OR "Name" = s."VocationalField2") as "VocationalField2ID",
    -- Map Specialization to SpecializationID
    (SELECT "Nr_SpecializationID" FROM public."Nr_Specializations" WHERE "Code" = s."Specialization" OR "Name" = s."Specialization") as "SpecializationID",
    -- Map Group to GroupID
    (SELECT "Nr_GroupID" FROM public."Nr_Groups" WHERE "GroupCode" = s."Group") as "GroupID",
    -- SPECIAL CASE: Map Tutor (code string) to TutorID (foreign key) - CRITICAL TEACHER CODE ISSUE
    (SELECT "Nr_TeacherID" FROM public."Nr_Teachers" WHERE "TeacherCode" = s."Tutor") as "TutorID",
    -- SPECIAL CASE: Map Mentor (code string) to MentorID (foreign key) - CRITICAL TEACHER CODE ISSUE
    (SELECT "Nr_TeacherID" FROM public."Nr_Teachers" WHERE "TeacherCode" = s."Mentor") as "MentorID",
    -- SPECIAL CASE: Map ResponsibleTrainer (code string) to ResponsibleTrainerID (foreign key) - CRITICAL TEACHER CODE ISSUE
    (SELECT "Nr_TeacherID" FROM public."Nr_Teachers" WHERE "TeacherCode" = s."ResponsibleTrainer") as "ResponsibleTrainerID",
    true as "IsActive",  -- All records are active initially
    s."Timestamp"
FROM public."Students" s;
```

#### 2.5 Migrate Student Status to Nr_StudentStatus
```sql
-- Insert student status information to Nr_StudentStatus, preserving old IDs
INSERT INTO public."Nr_StudentStatus" (
    "Nr_StatusID", "Nr_StudentID", "Active", "Archive", "Dismissed",
    "Disability", "SpecialEducationActive", "ForeignStudent",
    "PracticalPlaceRequired", "Resettler", "Retrainee", "GuestStudent",
    "NewApplicant", "PracticalPlace", "GuestStudentBilling"
)
SELECT
    "ID" as "Nr_StatusID",  -- Using student ID as status ID (preserving old ID)
    "ID" as "Nr_StudentID", -- Preserve the original student ID
    CASE WHEN "Archive" = 0 THEN 1 ELSE 0 END as "Active",  -- Active if not archived
    "Archive",
    CASE WHEN "DismissalDate" IS NOT NULL THEN 1 ELSE 0 END as "Dismissed",  -- Dismissed if dismissal date exists
    "Disability",
    "SpecialEducationActive",
    "ForeignStudent",
    "PracticalPlaceRequired",
    "Resettler",
    "Retrainee",
    "GuestStudent",
    "NewApplicant",
    "PracticalPlace",
    "GuestStudentBilling"
FROM public."Students";
```

### 3. Migration of Curriculum-Related Tables

#### 3.1 Migrate Curricula to Nr_Curricula
```sql
-- Insert curriculum data to Nr_Curricula
INSERT INTO public."Nr_Curricula" (
    "Nr_CurriculumID", "CurriculumName", "Description", "IsUpperSchool", 
    "ShortName", "Remark", "GradeSystem", "FirstYear", "LastYear", 
    "SchoolID", "Tenant", "Timestamp", "Status", "XmoodID", "GlobalUID", 
    "IsActive"
)
SELECT 
    "ID" as "Nr_CurriculumID",
    "CurriculumName",
    "Description",
    "IsUpperSchool",
    "ShortName",
    "Remark",
    "GradeSystem",
    "FirstYear",
    "LastYear",
    "SchoolID",
    "Tenant",
    "Timestamp",
    "Status",
    "XmoodID",
    "GlobalUID",
    "IsActive"
FROM public."Curricula";
-- Note: Adjust field mapping based on actual Curricula table structure
```

#### 3.2 Migrate Curriculum Subjects to Nr_CurriculumSubjects
```sql
-- Insert curriculum subjects to Nr_CurriculumSubjects
INSERT INTO public."Nr_CurriculumSubjects" (
    "Nr_CurriculumSubjectID", "Nr_CurriculumID", "Nr_SubjectID", 
    "GONumber", "TargetHours", "SubjectPosition", "Factor", 
    "CourseType", "Tenant", "YearlyHours", "Timestamp", "Status"
)
SELECT 
    "ID" as "Nr_CurriculumSubjectID",
    "CurriculumID" as "Nr_CurriculumID",
    -- Map Subject (code) to Nr_SubjectID
    (SELECT "Nr_SubjectID" FROM public."Nr_Subjects" WHERE "SubjectCode" = cs."SubjectCode") as "Nr_SubjectID",
    "GONumber",
    "TargetHours",
    "SubjectPosition",
    "Factor",
    "CourseType",
    "Tenant",
    "YearlyHours",
    "Timestamp",
    "Status"
FROM public."CurriculumSubjects" cs;
-- Note: Adjust field mapping based on actual CurriculumSubjects table structure
```

#### 3.3 Migrate Curriculum Events to Nr_CurriculumEvents
```sql
-- Insert curriculum events to Nr_CurriculumEvents
INSERT INTO public."Nr_CurriculumEvents" (
    "Nr_CurriculumEventID", "LessonNumber", "PlanNumber", "TeacherID", 
    "ClassID", "Nr_SubjectID", "Hours", "GivenHours", "IsAssigned", 
    "CoupledNumber", "Nr_RoomID", "Nr_HomeRoomID", "Identifier", 
    "NumberOfStudents", "BlockSize", "RoomHours", "TVN", "Distribution", 
    "WeekSets1", "WeekSets2", "Fixed", "Topic", "IsCoupled", 
    "Timestamp", "Tenant", "Status"
)
SELECT 
    "ID" as "Nr_CurriculumEventID",
    "LessonNumber",
    "PlanNumber",
    -- Map Teacher (code) to TeacherID
    (SELECT "Nr_TeacherID" FROM public."Nr_Teachers" WHERE "TeacherCode" = ce."TeacherCode") as "TeacherID",
    -- Map Class (code) to ClassID
    (SELECT "Nr_ClassID" FROM public."Nr_Classes" WHERE "OriginalID" = 
        (SELECT "ID" FROM public."Classes" WHERE "ShortName" = ce."ClassCode" OR "Description" = ce."ClassCode" LIMIT 1)
    ) as "ClassID",
    -- Map Subject (code) to Nr_SubjectID
    (SELECT "Nr_SubjectID" FROM public."Nr_Subjects" WHERE "SubjectCode" = ce."SubjectCode") as "Nr_SubjectID",
    "Hours",
    "GivenHours",
    "IsAssigned",
    "CouplingNumber" as "CoupledNumber",  -- Assuming field name difference
    -- Map Room (code) to Nr_RoomID
    NULL as "Nr_RoomID",  -- Need to implement room mapping
    -- Map HomeRoom (code) to Nr_HomeRoomID
    NULL as "Nr_HomeRoomID",  -- Need to implement home room mapping
    "Identifier",
    "NumberOfStudents",
    "BlockSize",
    "RoomHours",
    "TVN",
    "Distribution",
    "WeekSets1",
    "WeekSets2",
    "Fixed",
    "Topic",
    "IsCoupled",
    "Timestamp",
    "Tenant",
    "Status"
FROM public."CurriculumEvents" ce;
-- Note: Adjust field mapping based on actual CurriculumEvents table structure
```

### 4. Post-Migration Data Validation

#### 4.1 Verify Data Counts
```sql
-- Verify that all students were migrated
SELECT 
    (SELECT COUNT(*) FROM public."Students") AS original_student_count,
    (SELECT COUNT(*) FROM public."Nr_Students") AS new_student_count,
    (SELECT COUNT(*) FROM public."Nr_StudentSchoolInfo") AS student_school_info_count;

-- Verify that all classes were migrated
SELECT 
    (SELECT COUNT(*) FROM public."Classes") AS original_class_count,
    (SELECT COUNT(*) FROM public."Nr_Classes") AS new_class_count;

-- Verify that all teachers were migrated
SELECT 
    (SELECT COUNT(*) FROM public."Teachers") AS original_teacher_count,
    (SELECT COUNT(*) FROM public."Nr_Teachers") AS new_teacher_count;
```

#### 4.2 Verify Reference Table Population
```sql
-- Check if all required reference tables have data
SELECT 'Nr_SchoolYears' as table_name, COUNT(*) as record_count FROM public."Nr_SchoolYears"
UNION ALL
SELECT 'Nr_SchoolSemesters' as table_name, COUNT(*) as record_count FROM public."Nr_SchoolSemesters"
UNION ALL
SELECT 'Nr_Subjects' as table_name, COUNT(*) as record_count FROM public."Nr_Subjects"
UNION ALL
SELECT 'Nr_Teachers' as table_name, COUNT(*) as record_count FROM public."Nr_Teachers"
UNION ALL
SELECT 'Nr_Classes' as table_name, COUNT(*) as record_count FROM public."Nr_Classes";
```

#### 4.3 Verify Foreign Key Relationships
```sql
-- Check for any orphaned records in Nr_StudentSchoolInfo
SELECT COUNT(*) as orphaned_records
FROM public."Nr_StudentSchoolInfo" nssi
LEFT JOIN public."Nr_Students" ns ON nssi."Nr_StudentID" = ns."Nr_StudentID"
WHERE ns."Nr_StudentID" IS NULL;

-- Check for any orphaned records in Nr_Classes for teacher references
SELECT COUNT(*) as orphaned_class_teacher_records
FROM public."Nr_Classes" nc
LEFT JOIN public."Nr_Teachers" nt ON nc."ClassTeacherID" = nt."Nr_TeacherID"
WHERE nc."ClassTeacherID" IS NOT NULL AND nt."Nr_TeacherID" IS NULL;
```

### 5. Critical Special Case Handling

The following sections address the specific issues mentioned in your normalization plan:

#### 5.1 Handling the Critical Semester Reference Issue

The core issue identified in your normalization plan was that `Nr_StudentSchoolInfo` table stores semester information as a text field instead of referencing the proper `Nr_SchoolSemesters` table. This is now addressed in the migration by:

1. Creating proper records in `Nr_SchoolSemesters` table from the legacy `SchoolSemesters` data
2. Mapping the `SchoolSemester` character field to the `SchoolSemesterID` foreign key in the new structure
3. Ensuring referential integrity between student academic records and semester information

```sql
-- This query demonstrates the proper semester mapping
SELECT
    s."ID" as student_id,
    s."SchoolSemester" as original_semester,
    ss."Nr_SchoolSemesterID" as normalized_semester_id,
    ss."SemesterCode" as semester_code
FROM public."Students" s
LEFT JOIN public."Nr_SchoolSemesters" ss ON ss."SemesterCode" = s."SchoolSemester";
```

#### 5.2 Handling Teacher Code References

Multiple tables in the legacy schema use teacher codes (like "Tutor", "ClassTeacher", "Mentor") as character references instead of proper foreign keys. The migration properly maps these:

- `Tutor` (character code) → `TutorID` (foreign key to Nr_Teachers)
- `Mentor` (character code) → `MentorID` (foreign key to Nr_Teachers)
- `ResponsibleTrainer` (character code) → `ResponsibleTrainerID` (foreign key to Nr_Teachers)
- `ClassTeacher` (character code) → `ClassTeacherID` (foreign key to Nr_Teachers)
- `DeputyClassTeacher` (character code) → `DeputyClassTeacherID` (foreign key to Nr_Teachers)

```sql
-- Example of teacher code to ID mapping
SELECT
    t."ID" as legacy_teacher_id,
    t."Code" as teacher_code,
    t."Name" as teacher_name,
    nt."Nr_TeacherID" as normalized_teacher_id
FROM public."Teachers" t
LEFT JOIN public."Nr_Teachers" nt ON nt."TeacherCode" = t."Code";
```

#### 5.3 Handling Class and Room References

Class and room references that were stored as character codes are now properly normalized:

- `Class` (character code) → `ClassID` (foreign key to Nr_Classes)
- `Classroom` (character code) → `ClassroomID` (foreign key to Nr_Rooms)

This ensures that all relationships follow proper foreign key constraints in the normalized schema.

### 6. Migration Completion Steps

After running all the above scripts:

1. Run the validation queries to ensure data integrity
2. Re-enable any foreign key constraints that were disabled
3. Create any additional indexes needed for performance
4. Test application functionality with the new normalized schema
5. Archive or drop the old tables once you've confirmed everything works correctly

### Important Notes

1. Some lookups in the migration scripts may return NULL if there's no matching reference data. You may need to create default entries or handle these cases specifically.
2. The exact field names in the legacy tables might differ from what I've assumed. Please adjust the field mappings based on the actual table structures.
3. Some tables like CurriculumSubjects and CurriculumEvents require careful analysis of their actual structure to map correctly.
4. Always test these scripts on a copy of your database first before running on production.
5. The teacher code mapping assumes that the "Code" field in the legacy Teachers table matches the teacher references in other tables. Verify this mapping is correct for your specific database.

## Post-Migration Validation and Troubleshooting

### Common Issues and Solutions

1. **NULL Foreign Key Values**: If a migration results in NULL values in foreign key fields:
   ```sql
   -- Check for records with NULL foreign keys
   SELECT * FROM public."Nr_StudentSchoolInfo" WHERE "SchoolSemesterID" IS NULL;

   -- You may need to create default reference records or investigate the mapping
   ```

2. **Data Type Mismatches**: If you encounter type conversion errors, you may need to add CAST operations:
   ```sql
   -- Example: Converting text to date
   CAST("DateString" AS DATE)
   ```

3. **Duplicate Record Issues**: When creating reference tables, watch for duplicates:
   ```sql
   -- Check for potential duplicates before inserting
   SELECT "SchoolCategory", COUNT(*) FROM public."Students"
   GROUP BY "SchoolCategory" HAVING COUNT(*) > 1;
   ```

### Performance Considerations

For large databases, consider running the migration scripts in batches:

```sql
-- Example of batch processing
INSERT INTO public."Nr_Students" (...)
SELECT ... FROM public."Students"
WHERE "ID" BETWEEN 1 AND 1000;  -- First batch

INSERT INTO public."Nr_Students" (...)
SELECT ... FROM public."Students"
WHERE "ID" BETWEEN 1001 AND 2000;  -- Second batch
```

### Final Validation Steps

After completing the migration:

1. **Count validation**: Verify all records were migrated
2. **Relationship validation**: Ensure all foreign key relationships are valid
3. **Data integrity**: Check for any data quality issues
4. **Application testing**: Test all application functions with the new schema
5. **Performance testing**: Verify query performance with the new normalized structure

## Migration Rollback Plan

In case of critical issues, have a rollback plan ready:

1. Keep the original database backup accessible
2. Document the exact steps to restore the original schema
3. Have scripts ready to remove the new normalized tables if needed
4. Plan for the timeline needed to switch back to the original schema
