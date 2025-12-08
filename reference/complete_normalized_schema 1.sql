-- Complete Normalized Schema - Creation Order for 3NF Compliance
-- This file contains CREATE TABLE statements in the order required to respect foreign key dependencies

-- 1. Nr_Users (Base reference table for personal information)
-- This table contains personal information for both students and teachers
-- It is referenced by both Nr_Students and Nr_Teachers tables
/*
CREATE TABLE public."Nr_Users" (
    "UserID" integer NOT NULL PRIMARY KEY,
    "FirstName" character varying(100),
    "LastName" character varying(100),
    "BirthDate" date,
    "Gender" smallint,
    "NationalityID" integer,                  -- Foreign Key to Nationalities table
    "Email" character varying(150),
    "Phone" character varying(25),
    "Mobile" character varying(25),
    "PhotoFile" character varying(255),
    "Address" character varying(255),
    "City" character varying(100),
    "PostalCode" character varying(20),
    "Country" character varying(50),
    "TenantID" smallint,
    "GlobalUID" uuid,
    "LastModified" timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);
*/

-- 2. Nr_Subjects (Reference table for subjects - no dependencies)
CREATE TABLE public."Nr_Subjects" (
    "Nr_SubjectID" integer NOT NULL PRIMARY KEY,
    "SubjectCode" character varying(10),      -- Unique code for the subject
    "SubjectName" character varying(150),     -- Full name of the subject
    "ShortName" character varying(10),        -- Short abbreviation
    "SubjectType" character varying(5),       -- Type identifier (e.g., '1' for language, '2' for social studies, '3' for science)
    "SubjectArea" character varying(10),      -- Subject area grouping
    "SubjectSubarea" character varying(10),   -- More specific subject sub-area
    "SubjectPosition" smallint,               -- Position or ordering in curriculum
    "SchoolID" character varying(10),         -- School identifier for multi-school systems
    "Tenant" smallint DEFAULT 1 NOT NULL,
    "Timestamp" bytea NOT NULL,
    "Status" smallint DEFAULT 1,              -- Status field (1=active, 0=inactive) instead of deletion
    "XmoodID" uuid,
    "GlobalUID" uuid
);

-- 3. Nr_Rooms (Reference table for rooms - no dependencies)
CREATE TABLE public."Nr_Rooms" (
    "Nr_RoomID" integer NOT NULL PRIMARY KEY,
    "RoomNumber" character varying(10),       -- Room identifier (number or name)
    "RoomName" character varying(50),         -- Full room name
    "RoomType" character varying(20),         -- Type of room (classroom, lab, gym, etc.)
    "Capacity" smallint,                      -- Maximum capacity of the room
    "SchoolID" character varying(10),         -- School identifier for multi-school systems
    "Building" character varying(50),         -- Building where the room is located
    "Floor" character varying(10),            -- Floor number
    "Tenant" smallint DEFAULT 1 NOT NULL,
    "Timestamp" bytea NOT NULL,
    "Status" smallint DEFAULT 1,              -- Status field (1=active, 0=inactive) instead of deletion
    "XmoodID" uuid,
    "GlobalUID" uuid
);

-- 4. Nr_Teachers (Reference table for teachers - minimal dependencies)
-- Note: Personal information should be in Nr_Users table; this table contains academic/administrative information only
CREATE TABLE public."Nr_Teachers" (
    "Nr_TeacherID" integer NOT NULL PRIMARY KEY,
    "Nr_UserID" integer,                         -- Foreign Key to Nr_Users (for personal information)
    "TeacherCode" character varying(5),          -- For code-based lookups (not primary reference)
    "SchoolID" character varying(10),            -- School identifier for multi-school systems
    "StaffType" character varying(20),           -- Type of staff (e.g., full-time, part-time, substitute)
    "DepartmentID" integer,                      -- Department where teacher belongs
    "HireDate" date,                             -- Date when hired
    "TerminationDate" date,                      -- Date when employment ended (NULL if active)
    "Position" character varying(50),            -- Employment position title
    "SalaryGrade" character varying(10),         -- Salary grade level
    "ContractType" character varying(20),        -- Contract type (permanent, temporary, etc.)
    "IsFullTime" smallint DEFAULT 1,             -- 1=full-time, 0=part-time
    "MaxTeachingHours" smallint,                 -- Maximum teaching hours allowed
    "Tenant" smallint DEFAULT 1 NOT NULL,
    "Timestamp" bytea NOT NULL,
    "Status" smallint DEFAULT 1,                 -- Status field (1=active, 0=inactive) instead of deletion
    "XmoodID" uuid,
    "GlobalUID" uuid,
    -- Foreign Key Constraints
    CONSTRAINT "FK_Teachers_User" FOREIGN KEY ("Nr_UserID") REFERENCES public."Nr_Users"("UserID"),
    CONSTRAINT "FK_Teachers_School" FOREIGN KEY ("SchoolID") REFERENCES public."Nr_Schools"("SchoolID")
);

-- 5. Reference tables with Nr_ prefix and proper attributes

-- 5a. Nr_SchoolYears (Reference table for school years)
CREATE TABLE public."Nr_SchoolYears" (
    "Nr_SchoolYearID" integer NOT NULL PRIMARY KEY,
    "YearCode" character varying(10),
    "Description" character varying(50),
    "StartDate" date,
    "EndDate" date,
    "SchoolID" character varying(10),
    "Tenant" smallint DEFAULT 1 NOT NULL,
    "Timestamp" bytea NOT NULL,
    "Status" smallint DEFAULT 1,              -- Status field (1=active, 0=inactive)
    "XmoodID" uuid,
    "GlobalUID" uuid
);

-- 5b. Nr_SchoolSemesters (Reference table for school semesters)
CREATE TABLE public."Nr_SchoolSemesters" (
    "Nr_SchoolSemesterID" integer NOT NULL PRIMARY KEY,
    "SemesterCode" character varying(15),
    "Description" character varying(50),
    "StartDate" date,
    "EndDate" date,
    "SchoolID" character varying(10),
    "Tenant" smallint DEFAULT 1 NOT NULL,
    "Timestamp" bytea NOT NULL,
    "Status" smallint DEFAULT 1,              -- Status field (1=active, 0=inactive)
    "XmoodID" uuid,
    "GlobalUID" uuid
);

-- 5c. Nr_SchoolCategories (Reference table for school categories)
CREATE TABLE public."Nr_SchoolCategories" (
    "Nr_SchoolCategoryID" integer NOT NULL PRIMARY KEY,
    "Name" character varying(100),
    "Code" character varying(10),
    "Description" text,
    "SchoolID" character varying(10),
    "Tenant" smallint DEFAULT 1 NOT NULL,
    "Timestamp" bytea NOT NULL,
    "Status" smallint DEFAULT 1,              -- Status field (1=active, 0=inactive)
    "XmoodID" uuid,
    "GlobalUID" uuid
);

-- 5d. Nr_SchoolTypes (Reference table for school types)
CREATE TABLE public."Nr_SchoolTypes" (
    "Nr_SchoolTypeID" integer NOT NULL PRIMARY KEY,
    "Name" character varying(100),
    "Code" character varying(10),
    "Description" text,
    "SchoolID" character varying(10),
    "Tenant" smallint DEFAULT 1 NOT NULL,
    "Timestamp" bytea NOT NULL,
    "Status" smallint DEFAULT 1,              -- Status field (1=active, 0=inactive)
    "XmoodID" uuid,
    "GlobalUID" uuid
);

-- 5e. Nr_Professions (Reference table for professions)
CREATE TABLE public."Nr_Professions" (
    "Nr_ProfessionID" integer NOT NULL PRIMARY KEY,
    "Name" character varying(100),
    "Code" character varying(10),
    "Description" text,
    "SchoolID" character varying(10),
    "Tenant" smallint DEFAULT 1 NOT NULL,
    "Timestamp" bytea NOT NULL,
    "Status" smallint DEFAULT 1,              -- Status field (1=active, 0=inactive)
    "XmoodID" uuid,
    "GlobalUID" uuid
);

-- 5f. Nr_ProfessionalFields (Reference table for professional fields)
CREATE TABLE public."Nr_ProfessionalFields" (
    "Nr_ProfessionalFieldID" integer NOT NULL PRIMARY KEY,
    "Name" character varying(100),
    "Code" character varying(10),
    "Description" text,
    "SchoolID" character varying(10),
    "Tenant" smallint DEFAULT 1 NOT NULL,
    "Timestamp" bytea NOT NULL,
    "Status" smallint DEFAULT 1,              -- Status field (1=active, 0=inactive)
    "XmoodID" uuid,
    "GlobalUID" uuid
);

-- 5g. Nr_VocationalFields (Reference table for vocational fields)
CREATE TABLE public."Nr_VocationalFields" (
    "Nr_VocationalFieldID" integer NOT NULL PRIMARY KEY,
    "Name" character varying(100),
    "Code" character varying(10),
    "Description" text,
    "SchoolID" character varying(10),
    "Tenant" smallint DEFAULT 1 NOT NULL,
    "Timestamp" bytea NOT NULL,
    "Status" smallint DEFAULT 1,              -- Status field (1=active, 0=inactive)
    "XmoodID" uuid,
    "GlobalUID" uuid
);

-- 5h. Nr_Specializations (Reference table for specializations)
CREATE TABLE public."Nr_Specializations" (
    "Nr_SpecializationID" integer NOT NULL PRIMARY KEY,
    "Name" character varying(100),
    "Code" character varying(10),
    "Description" text,
    "SchoolID" character varying(10),
    "Tenant" smallint DEFAULT 1 NOT NULL,
    "Timestamp" bytea NOT NULL,
    "Status" smallint DEFAULT 1,              -- Status field (1=active, 0=inactive)
    "XmoodID" uuid,
    "GlobalUID" uuid
);

-- 5i. Nr_Groups (Reference table for groups)
CREATE TABLE public."Nr_Groups" (
    "Nr_GroupID" integer NOT NULL PRIMARY KEY,
    "GroupCode" character varying(10),
    "GroupName" character varying(100),
    "Description" text,
    "SchoolID" character varying(10),
    "Tenant" smallint DEFAULT 1 NOT NULL,
    "Timestamp" bytea NOT NULL,
    "Status" smallint DEFAULT 1,              -- Status field (1=active, 0=inactive)
    "XmoodID" uuid,
    "GlobalUID" uuid
);

-- 5j. Nr_GraduationYears (Reference table for graduation years)
CREATE TABLE public."Nr_GraduationYears" (
    "Nr_GraduationYearID" integer NOT NULL PRIMARY KEY,
    "Year" character varying(10),
    "Description" character varying(50),
    "SchoolID" character varying(10),
    "Tenant" smallint DEFAULT 1 NOT NULL,
    "Timestamp" bytea NOT NULL,
    "Status" smallint DEFAULT 1,              -- Status field (1=active, 0=inactive)
    "XmoodID" uuid,
    "GlobalUID" uuid
);

-- 5k. Nr_Classes (Reference table for classes - depends on curriculum and reference tables)
CREATE TABLE public."Nr_Classes" (
    "Nr_ClassID" integer NOT NULL PRIMARY KEY,
    "SchoolID" character varying(10),
    "SchoolYearID" integer,                   -- Foreign Key to Nr_SchoolYears table
    "SchoolSemesterID" integer,               -- Foreign Key to Nr_SchoolSemesters table
    "Description" character varying(150),
    "ShortName" character varying(10),
    "SchoolCategoryID" integer,               -- Foreign Key to Nr_SchoolCategories table
    "ClassLevel" character varying(3),
    "ClassTeacherID" integer,                 -- Foreign Key to Nr_Teachers table (Nr_TeacherID)
    "DeputyClassTeacherID" integer,           -- Foreign Key to Nr_Teachers table (Nr_TeacherID)
    "ClassroomID" integer,                    -- Foreign Key to Nr_Rooms table
    "MaxStudents" smallint,
    "TeachingFormID" integer,                 -- Foreign Key to Nr_TeachingForms table
    "ClassCategoryID" integer,                -- Foreign Key to Nr_ClassCategories table
    "DifferentiationID" integer,              -- Foreign Key to Nr_Differentiation table
    "DefaultCurriculumID" integer,            -- Foreign Key to Nr_Curricula table
    "BlockGroupID" integer,                   -- Foreign Key to Nr_BlockGroups table
    "RequirementBasis" character varying(50),
    "BlockKey" character varying(100),
    "BlockTypeID" integer,                    -- Foreign Key to Nr_BlockTypes table
    "Remarks" character varying(100),
    "DepartmentID" integer,                   -- Foreign Key to Nr_Departments table
    "EducationPathID" integer,                -- Foreign Key to Nr_EducationPaths table
    "SpecializationID" integer,               -- Foreign Key to Nr_Specializations table
    "BranchID" integer,                       -- Foreign Key to Nr_Branches table
    "CourseID" integer,                       -- Foreign Key to Nr_Courses table
    "OfficialName" character varying(30),
    "EthicsClass" smallint DEFAULT 0,
    "SpecialFeature" character varying(2),
    "BranchOfficeID" integer,                 -- Foreign Key to Nr_BranchOffices table
    "ExplanationFeature" character varying(2),
    "BlockWeeksCount" smallint,
    "Statistics" smallint DEFAULT 1,
    "ProfessionalFieldID" integer,            -- Foreign Key to Nr_ProfessionalFields table
    "ProfessionID" integer,                   -- Foreign Key to Nr_Professions table
    "LevelID" integer,                        -- Foreign Key to Nr_Levels table
    "VocationalField2ID" integer,             -- Foreign Key to Nr_VocationalFields table
    "IdentifierCode" character varying(10),
    "SchoolPartID" integer,                   -- Foreign Key to Nr_SchoolParts table
    "ClassTypeID" integer,                    -- Foreign Key to Nr_ClassTypes table
    "QualificationID" integer,                -- Foreign Key to Nr_Qualifications table
    "CrossCountryVocationalClasses" smallint,
    "ApplicantClass" smallint DEFAULT 0,
    "InTimetable" smallint DEFAULT 0,
    "ClassTeacherHours" real,
    "ClassHours" real,
    "Timestamp" bytea NOT NULL,
    "UntisID" character varying(50),
    "Tenant" smallint DEFAULT 1 NOT NULL,
    "XmoodID" uuid,
    "GlobalUID" uuid,
    "GraduationClass" smallint DEFAULT 0 NOT NULL,
    "Status" smallint DEFAULT 1,              -- Status field instead of deletion
    -- Foreign Key Constraints
    CONSTRAINT "FK_Classes_SchoolYear" FOREIGN KEY ("SchoolYearID") REFERENCES public."Nr_SchoolYears"("Nr_SchoolYearID"),
    CONSTRAINT "FK_Classes_SchoolSemester" FOREIGN KEY ("SchoolSemesterID") REFERENCES public."Nr_SchoolSemesters"("Nr_SchoolSemesterID"),
    CONSTRAINT "FK_Classes_SchoolCategory" FOREIGN KEY ("SchoolCategoryID") REFERENCES public."Nr_SchoolCategories"("Nr_SchoolCategoryID"),
    CONSTRAINT "FK_Classes_ClassTeacher" FOREIGN KEY ("ClassTeacherID") REFERENCES public."Nr_Teachers"("Nr_TeacherID"),
    CONSTRAINT "FK_Classes_DeputyClassTeacher" FOREIGN KEY ("DeputyClassTeacherID") REFERENCES public."Nr_Teachers"("Nr_TeacherID"),
    CONSTRAINT "FK_Classes_Classroom" FOREIGN KEY ("ClassroomID") REFERENCES public."Nr_Rooms"("Nr_RoomID"),
    CONSTRAINT "FK_Classes_Curriculum" FOREIGN KEY ("DefaultCurriculumID") REFERENCES public."Nr_Curricula"("Nr_CurriculumID"),
    CONSTRAINT "FK_Classes_ProfessionalField" FOREIGN KEY ("ProfessionalFieldID") REFERENCES public."Nr_ProfessionalFields"("Nr_ProfessionalFieldID"),
    CONSTRAINT "FK_Classes_Profession" FOREIGN KEY ("ProfessionID") REFERENCES public."Nr_Professions"("Nr_ProfessionID"),
    CONSTRAINT "FK_Classes_Specialization" FOREIGN KEY ("SpecializationID") REFERENCES public."Nr_Specializations"("Nr_SpecializationID"),
    CONSTRAINT "FK_Classes_VocationalField2" FOREIGN KEY ("VocationalField2ID") REFERENCES public."Nr_VocationalFields"("Nr_VocationalFieldID")
);

-- 6. Nr_Curricula (Master table - depends on school context)
CREATE TABLE public."Nr_Curricula" (
    "Nr_CurriculumID" integer NOT NULL PRIMARY KEY,
    "CurriculumName" character varying(80),
    "Description" character varying(255),
    "IsUpperSchool" smallint,
    "ShortName" character varying(20),
    "Remark" character varying(255),
    "GradeSystem" character varying(20),
    "FirstYear" integer,
    "LastYear" integer,
    "SchoolID" character varying(10),         -- Added SchoolID for multi-school context
    "Tenant" smallint DEFAULT 1 NOT NULL,
    "Timestamp" bytea NOT NULL,
    "Status" smallint DEFAULT 1,              -- Status field instead of deletion
    "XmoodID" uuid,
    "GlobalUID" uuid,
    "IsActive" smallint DEFAULT 1
);

-- 7. Nr_Students (Core student table - depends on Nr_Users)
CREATE TABLE public."Nr_Students" (
    "Nr_StudentID" integer NOT NULL PRIMARY KEY,
    "Nr_UserID" integer, -- Foreign Key to Nr_Users
    "YearOfArrival" character varying(4),
    "Country" character varying(4),
    "OfAge" smallint DEFAULT 0,
    "FinancialAid" smallint DEFAULT 0,
    "Disability" smallint DEFAULT 0,
    "EducationPath" character varying(100),
    "IdentifierCode" character varying(10),
    "Tenant" smallint DEFAULT 1 NOT NULL,
    "Timestamp" bytea NOT NULL,
    -- Foreign Key Constraints
    CONSTRAINT "FK_Students_User" FOREIGN KEY ("Nr_UserID") REFERENCES public."Nr_Users"("UserID")
);

-- 8. Nr_StudentSchoolInfo (Academic period specific data - depends on multiple tables)
CREATE TABLE public."Nr_StudentSchoolInfo" (
    "Nr_SchoolInfoID" integer NOT NULL PRIMARY KEY,
    "Nr_StudentID" integer, -- Foreign Key to Nr_Students
    "SchoolYearID" integer, -- Foreign Key to Nr_SchoolYears table
    "SchoolSemesterID" integer, -- Foreign Key to Nr_SchoolSemesters.ID
    "ClassID" integer, -- Foreign Key to Nr_Classes.ID 
    "SchoolSemesterNumber" integer, -- From original table
    "ProfessionID" integer, -- Foreign Key to Nr_Professions table (can be NULL)
    "CurriculumID" integer, -- Foreign Key to Nr_Curricula.ID 
    "CurriculumName" character varying(80), -- Transitive dependency - consider removing in full normalization
    "Branch" character varying(1),
    "Level" character varying(3),
    "SchoolCategoryID" integer, -- Foreign Key to Nr_SchoolCategories table (can be NULL)
    "SchoolTypeID" integer, -- Foreign Key to Nr_SchoolTypes table (can be NULL)
    "SchoolTypeText" character varying(50), -- Transitive dependency - consider removing in full normalization
    "SchoolYearCode" double precision, -- From original table
    "EntryDate" timestamp without time zone,
    "GraduationYearID" integer, -- Foreign Key to Nr_GraduationYears table (can be NULL)
    "Status" smallint, -- Student status in this academic period
    "TransferDate" timestamp without time zone, -- When student transferred
    "CareerStatus" smallint, -- Career status in this academic period
    "SchoolDataStatus" smallint, -- School data status in this academic period
    "EducationStatus" smallint, -- Education status in this academic period
    "FormSuffix" character varying(3), -- Form suffix in this academic period
    "DismissalDate" timestamp without time zone, -- Dismissal date if any
    "Reason" character varying(50), -- Reason for dismissal or other status
    "PartnerSchool" character varying(40), -- Partner school in this academic period
    "PromotionEligibility" character varying(20), -- Promotion eligibility status
    "ApprovedUntil" timestamp without time zone, -- Until when approved
    "DeviationFromStandardTime" character varying(10), -- Deviation from standard time
    "Repeater" smallint DEFAULT 0, -- Is this student a repeater in this period
    "RepetitionReason" character varying(50), -- Reason for repetition
    "FreeRepeater" smallint DEFAULT 0, -- Is this a free repeater in this period
    "CompanyLock" smallint DEFAULT 0, -- Company lock status in this period
    "RequirementBasis" character varying(100), -- Requirement basis in this period
    "AdditionalRequirementBasis" character varying(100), -- Additional requirement basis
    "SecondLanguageNew" smallint DEFAULT 0,
    "AdditionalLessons" smallint DEFAULT 0,
    "EmploymentContract" character varying(20),
    "LastExam" character varying(255),
    "EntryTrainingSemester" character varying(20),
    "APOCode" smallint,
    "ProfessionalFieldID" integer, -- Foreign Key to Nr_ProfessionalFields table (can be NULL)
    "VocationalField2ID" integer, -- Foreign Key to Nr_VocationalFields table (can be NULL)
    "SpecializationID" integer, -- Foreign Key to Nr_Specializations table (can be NULL)
    "GroupID" integer, -- Foreign Key to Nr_Groups table (can be NULL)
    "TutorID" integer, -- Foreign Key to Nr_Teachers (Nr_TeacherID, can be NULL)
    "MentorID" integer, -- Foreign Key to Nr_Teachers (Nr_TeacherID, can be NULL)
    "ResponsibleTrainerID" integer, -- Foreign Key to Nr_Teachers (Nr_TeacherID, can be NULL)
    "IsActive" boolean DEFAULT true, -- To track current vs historical records
    "Timestamp" bytea NOT NULL, -- For concurrency control
    -- Foreign Key Constraints
    CONSTRAINT "FK_StudentSchoolInfo_Student" FOREIGN KEY ("Nr_StudentID") REFERENCES public."Nr_Students"("Nr_StudentID"),
    CONSTRAINT "FK_StudentSchoolInfo_SchoolYear" FOREIGN KEY ("SchoolYearID") REFERENCES public."Nr_SchoolYears"("Nr_SchoolYearID"),
    CONSTRAINT "FK_StudentSchoolInfo_SchoolSemester" FOREIGN KEY ("SchoolSemesterID") REFERENCES public."Nr_SchoolSemesters"("Nr_SchoolSemesterID"),
    CONSTRAINT "FK_StudentSchoolInfo_Class" FOREIGN KEY ("ClassID") REFERENCES public."Nr_Classes"("Nr_ClassID"),
    CONSTRAINT "FK_StudentSchoolInfo_Curriculum" FOREIGN KEY ("CurriculumID") REFERENCES public."Nr_Curricula"("Nr_CurriculumID"),
    CONSTRAINT "FK_StudentSchoolInfo_SchoolType" FOREIGN KEY ("SchoolTypeID") REFERENCES public."Nr_SchoolTypes"("Nr_SchoolTypeID"),
    CONSTRAINT "FK_StudentSchoolInfo_Profession" FOREIGN KEY ("ProfessionID") REFERENCES public."Nr_Professions"("Nr_ProfessionID"),
    CONSTRAINT "FK_StudentSchoolInfo_ProfessionalField" FOREIGN KEY ("ProfessionalFieldID") REFERENCES public."Nr_ProfessionalFields"("Nr_ProfessionalFieldID"),
    CONSTRAINT "FK_StudentSchoolInfo_VocationalField2" FOREIGN KEY ("VocationalField2ID") REFERENCES public."Nr_VocationalFields"("Nr_VocationalFieldID"),
    CONSTRAINT "FK_StudentSchoolInfo_Specialization" FOREIGN KEY ("SpecializationID") REFERENCES public."Nr_Specializations"("Nr_SpecializationID"),
    CONSTRAINT "FK_StudentSchoolInfo_Group" FOREIGN KEY ("GroupID") REFERENCES public."Nr_Groups"("Nr_GroupID"),
    CONSTRAINT "FK_StudentSchoolInfo_Tutor" FOREIGN KEY ("TutorID") REFERENCES public."Nr_Teachers"("Nr_TeacherID"),
    CONSTRAINT "FK_StudentSchoolInfo_Mentor" FOREIGN KEY ("MentorID") REFERENCES public."Nr_Teachers"("Nr_TeacherID"),
    CONSTRAINT "FK_StudentSchoolInfo_ResponsibleTrainer" FOREIGN KEY ("ResponsibleTrainerID") REFERENCES public."Nr_Teachers"("Nr_TeacherID")
);

-- 9. Nr_StudentStatus (Overall student status - depends on Nr_Students)
CREATE TABLE public."Nr_StudentStatus" (
    "Nr_StatusID" integer NOT NULL PRIMARY KEY,
    "Nr_StudentID" integer, -- Foreign Key to Nr_Students
    "Active" smallint DEFAULT 1,
    "Archive" smallint DEFAULT 0,
    "Dismissed" smallint DEFAULT 0,
    "Disability" smallint DEFAULT 0,
    "SpecialEducationActive" smallint DEFAULT 0,
    "ForeignStudent" smallint DEFAULT 0,
    "PracticalPlaceRequired" smallint DEFAULT 0,
    "Resettler" smallint DEFAULT 0,
    "Retrainee" smallint DEFAULT 0,
    "GuestStudent" smallint DEFAULT 0,
    "NewApplicant" smallint DEFAULT 0,
    "PracticalPlace" smallint DEFAULT 0,
    "GuestStudentBilling" smallint DEFAULT 0,
    -- Foreign Key Constraints
    CONSTRAINT "FK_StudentStatus_Student" FOREIGN KEY ("Nr_StudentID") REFERENCES public."Nr_Students"("Nr_StudentID")
);

-- 10. Nr_CurriculumRemarks (Depends on Nr_Curricula)
CREATE TABLE public."Nr_CurriculumRemarks" (
    "Nr_CurriculumRemarkID" integer NOT NULL PRIMARY KEY,
    "Nr_CurriculumID" integer,               -- Foreign Key to Nr_Curricula
    "Description" character varying(30),
    "DescriptionPosition" smallint,
    "Timestamp" bytea NOT NULL,
    "Tenant" smallint DEFAULT 1 NOT NULL,
    "CharacterCount" smallint,
    "Status" smallint DEFAULT 1,              -- Status field instead of deletion
    -- Foreign Key Constraints
    CONSTRAINT "FK_CurriculumRemarks_Curriculum" FOREIGN KEY ("Nr_CurriculumID")
        REFERENCES public."Nr_Curricula"("Nr_CurriculumID")
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- 11. Nr_CurriculumSubjects (Depends on Nr_Curricula and Nr_Subjects)
CREATE TABLE public."Nr_CurriculumSubjects" (
    "Nr_CurriculumSubjectID" integer NOT NULL PRIMARY KEY,
    "Nr_CurriculumID" integer,                -- Foreign Key to Nr_Curricula
    "Nr_SubjectID" integer,                   -- Foreign Key to Nr_Subjects (updated reference)
    "GONumber" smallint,
    "TargetHours" double precision,
    "SubjectPosition" smallint,
    "Factor" double precision,
    "CourseType" character varying(5),
    "Tenant" smallint DEFAULT 1 NOT NULL,
    "YearlyHours" smallint,
    "Timestamp" bytea NOT NULL,
    "Status" smallint DEFAULT 1,              -- Status field instead of deletion
    -- Foreign Key Constraints
    CONSTRAINT "FK_CurriculumSubjects_Curriculum" FOREIGN KEY ("Nr_CurriculumID")
        REFERENCES public."Nr_Curricula"("Nr_CurriculumID")
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "FK_CurriculumSubjects_Subject" FOREIGN KEY ("Nr_SubjectID")
        REFERENCES public."Nr_Subjects"("Nr_SubjectID")
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- 12. Nr_CurriculumEvents (Depends on multiple tables: Teachers, Classes, Subjects, Rooms)
CREATE TABLE public."Nr_CurriculumEvents" (
    "Nr_CurriculumEventID" integer NOT NULL PRIMARY KEY,
    "LessonNumber" integer,
    "PlanNumber" integer,
    "TeacherID" integer,                      -- Foreign Key to Nr_Teachers
    "ClassID" integer,                        -- Foreign Key to Nr_Classes
    "Nr_SubjectID" integer,                   -- Foreign Key to Nr_Subjects (updated reference)
    "Hours" smallint,
    "GivenHours" double precision,
    "IsAssigned" smallint,
    "CoupledNumber" integer,
    "Nr_RoomID" integer,                      -- Foreign Key to Nr_Rooms (updated reference)
    "Nr_HomeRoomID" integer,                  -- Foreign Key to Nr_Rooms (updated reference)
    "Identifier" character varying(5),
    "NumberOfStudents" smallint,
    "BlockSize" smallint,
    "RoomHours" smallint,
    "TVN" character varying(1),
    "Distribution" character varying(10),
    "WeekSets1" integer,
    "WeekSets2" integer,
    "Fixed" smallint,
    "Topic" character varying(50),
    "IsCoupled" smallint,
    "Timestamp" bytea NOT NULL,
    "Tenant" smallint DEFAULT 1 NOT NULL,
    "Status" smallint DEFAULT 1,              -- Status field instead of deletion
    -- Foreign Key Constraints
    CONSTRAINT "FK_CurriculumEvents_Teacher" FOREIGN KEY ("TeacherID")
        REFERENCES public."Nr_Teachers"("Nr_TeacherID")
        ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT "FK_CurriculumEvents_Class" FOREIGN KEY ("ClassID")
        REFERENCES public."Nr_Classes"("Nr_ClassID")
        ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT "FK_CurriculumEvents_Subject" FOREIGN KEY ("Nr_SubjectID")
        REFERENCES public."Nr_Subjects"("Nr_SubjectID")
        ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT "FK_CurriculumEvents_Room" FOREIGN KEY ("Nr_RoomID")
        REFERENCES public."Nr_Rooms"("Nr_RoomID")
        ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT "FK_CurriculumEvents_HomeRoom" FOREIGN KEY ("Nr_HomeRoomID")
        REFERENCES public."Nr_Rooms"("Nr_RoomID")
        ON DELETE SET NULL ON UPDATE CASCADE
);