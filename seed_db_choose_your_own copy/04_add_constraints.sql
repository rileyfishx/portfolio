-- =====================================================================
-- 04_add_constraints.sql
-- =====================================================================
-- WHY THIS SCRIPT EXISTS:
-- The CREATE TABLE script (03) already enforces structural rules: NOT
-- NULL, foreign keys, data types. But it does NOT stop someone from
-- inserting a patient with Age = -5, or BMI = 0, or Annual_Visits =
-- 9999. The column TYPE allows those values (they're still valid
-- numbers) -- the column doesn't know they're nonsensical for a human
-- being. CHECK constraints close that gap: they enforce "this number
-- is allowed by the data type AND it makes sense for this real-world
-- column."
--
-- Bounds below were set by profiling the actual 2000-row CSV (exact
-- min/max for every numeric column), then widening slightly so the
-- constraint catches genuinely bad data (negative numbers, impossible
-- values) without rejecting a real future patient who happens to fall
-- just outside this particular sample's range. A CHECK constraint
-- should catch IMPOSSIBLE data, not just data that's unusual.
--
-- Run this AFTER 03_create_patients_table.sql -- it adds constraints
-- to a table that must already exist.
--
-- IMPORTANT: ALTER TABLE ... ADD CONSTRAINT will FAIL if existing rows
-- already violate the constraint. If you already loaded the CSV before
-- running this script, that's fine -- the real data was profiled to
-- set these bounds, so it will pass. But if you load data in a
-- different order, run constraints BEFORE loading bad data so you
-- catch problems at insert time instead of finding them later.
-- =====================================================================

USE patient_data;

ALTER TABLE patients
    ADD CONSTRAINT chk_patients_age
        CHECK (age BETWEEN 0 AND 120),

    ADD CONSTRAINT chk_patients_height
        CHECK (height_cm BETWEEN 50 AND 250),

    ADD CONSTRAINT chk_patients_weight
        CHECK (weight_kg BETWEEN 2 AND 300),

    ADD CONSTRAINT chk_patients_bmi
        CHECK (bmi > 0 AND bmi < 100),

    ADD CONSTRAINT chk_patients_chronic_conditions
        CHECK (num_chronic_conditions BETWEEN 0 AND 20),

    ADD CONSTRAINT chk_patients_annual_visits
        CHECK (annual_visits >= 0),

    ADD CONSTRAINT chk_patients_billing
        CHECK (avg_billing_amount >= 0),

    ADD CONSTRAINT chk_patients_days_since_visit
        CHECK (days_since_last_visit >= 0);

-- NOTE ON MySQL VERSIONS:
-- CHECK constraints are only enforced starting in MySQL 8.0.16+. In
-- older MySQL versions, this syntax is accepted but silently ignored
-- (the constraint is parsed but never actually checked). Run this to
-- confirm your version supports it:
--
--   SELECT VERSION();
--
-- If you're on 8.0.16 or later, you're fine. Homebrew installs the
-- current MySQL release by default, so this should not be an issue
-- on a fresh Mac install -- but it's worth knowing this is a version-
-- dependent feature if these constraints ever seem to not be working.
