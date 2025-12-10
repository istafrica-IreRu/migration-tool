-- Column additions to be run after Phase 1 (raw migration)
-- This ensures columns exist before Phase 2 (normalization) runs
-- Generated from resources/schema_definition.json

-- Table: Students
ALTER TABLE public."Students" ADD COLUMN IF NOT EXISTS "CreatedAt" TIMESTAMP NOT NULL DEFAULT NOW();
ALTER TABLE public."Students" ADD COLUMN IF NOT EXISTS "UpdatedAt" TIMESTAMP NOT NULL DEFAULT NOW();
ALTER TABLE public."Students" ADD COLUMN IF NOT EXISTS "IsActive" BOOLEAN NOT NULL DEFAULT true;

-- Table: Teachers
ALTER TABLE public."Teachers" ADD COLUMN IF NOT EXISTS "CreatedAt" TIMESTAMP NOT NULL DEFAULT NOW();
ALTER TABLE public."Teachers" ADD COLUMN IF NOT EXISTS "UpdatedAt" TIMESTAMP NOT NULL DEFAULT NOW();
ALTER TABLE public."Teachers" ADD COLUMN IF NOT EXISTS "IsActive" BOOLEAN NOT NULL DEFAULT true;

-- Table: Classes
ALTER TABLE public."Classes" ADD COLUMN IF NOT EXISTS "CreatedAt" TIMESTAMP NOT NULL DEFAULT NOW();
ALTER TABLE public."Classes" ADD COLUMN IF NOT EXISTS "UpdatedAt" TIMESTAMP NOT NULL DEFAULT NOW();

-- Table: ApplicantProcedureData
ALTER TABLE public."ApplicantProcedureData" ADD COLUMN IF NOT EXISTS "IsDraft" SMALLINT NOT NULL DEFAULT 0;

-- Table: ApplicantProcedure
-- Note: handling nullable fields correctly with defaults 
ALTER TABLE public."ApplicantProcedure" ADD COLUMN IF NOT EXISTS "Status" SMALLINT NOT NULL DEFAULT 1;
ALTER TABLE public."ApplicantProcedure" ADD COLUMN IF NOT EXISTS "IsDraft" SMALLINT NOT NULL DEFAULT 0;
ALTER TABLE public."ApplicantProcedure" ADD COLUMN IF NOT EXISTS "GradingScale" VARCHAR(255) DEFAULT '6_POINT';
ALTER TABLE public."ApplicantProcedure" ADD COLUMN IF NOT EXISTS "AgeLimit" INTEGER DEFAULT 12;

-- Table: ApplicantTable
ALTER TABLE public."ApplicantTable" ADD COLUMN IF NOT EXISTS "UserID" INTEGER;
