-- =====================================================================
-- 02_create_lookup_tables.sql
-- =====================================================================
-- WHY THIS SCRIPT EXISTS:
-- Looking at the CSV, three columns repeat the same small set of values
-- across all 2000 rows:
--
--   State              -> only 10 distinct values (CA, FL, GA, IL, MI,
--                          NC, NY, OH, PA, TX)
--   Insurance_Type      -> only 4 distinct values (Medicaid, Medicare,
--                          Private, Self-Pay)
--   Primary_Condition   -> only 9 distinct values, PLUS some patients
--                          have no condition at all (495 rows are blank)
--
-- Storing "Medicare" as a text string 2000 times wastes space and risks
-- typos ("medicare" vs "Medicare" vs "Medi-care" all become different
-- values to a database). Pulling repeated values into their own lookup
-- table and referencing them by a small integer ID is the textbook fix
-- — this is "normalization," specifically getting rid of repeating
-- groups of plain-text values.
--
-- Run this AFTER 01_create_database.sql.
-- =====================================================================

USE patient_data;

-- ---------------------------------------------------------------------
-- states: reference table for the 10 U.S. states seen in the data
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS states (
    state_id    TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    state_code  CHAR(2) NOT NULL UNIQUE   -- e.g. 'CA', 'TX' — always 2 chars
);

-- ---------------------------------------------------------------------
-- insurance_types: reference table for the 4 insurance categories
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS insurance_types (
    insurance_type_id  TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    type_name          VARCHAR(20) NOT NULL UNIQUE   -- 'Medicaid', 'Self-Pay', etc.
);

-- ---------------------------------------------------------------------
-- conditions: reference table for the 9 primary conditions
-- ---------------------------------------------------------------------
-- NOTE: ~25% of patients (495 of 2000) have NO primary condition listed.
-- That's a real, meaningful "no condition" state — not missing/dirty
-- data we need to clean. We will NOT force a "Unknown" row into this
-- table. Instead, the patients table will allow condition_id to be
-- NULL, which correctly means "no primary condition on record."
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS conditions (
    condition_id    TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    condition_name  VARCHAR(20) NOT NULL UNIQUE   -- 'Diabetes', 'COPD', etc.
);
