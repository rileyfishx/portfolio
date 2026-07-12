-- =====================================================================
-- 03_create_patients_table.sql
-- =====================================================================
-- WHY THIS SCRIPT EXISTS:
-- This is the main fact table — one row per patient, matching the CSV's
-- grain exactly (2000 rows in, 2000 rows expected out). Instead of
-- storing State/Insurance_Type/Primary_Condition as raw text, we store
-- a small integer ID that points back to the lookup tables created in
-- 02_create_lookup_tables.sql. This is why that script had to run first
-- — these FOREIGN KEY constraints will fail if the lookup tables don't
-- exist yet.
--
-- Column-by-column reasoning (driven by profiling the actual CSV):
--
--   patient_id   -> CSV uses values like 'P10000', always 6 chars,
--                    already unique (checked: 0 duplicates across 2000
--                    rows). It's a natural key, so we use it directly
--                    as the PRIMARY KEY rather than inventing a
--                    separate surrogate auto-increment ID.
--   age          -> CSV range is 18-87, fits comfortably in TINYINT
--                    UNSIGNED (0-255), no need for a bigger type.
--   gender       -> Only 2 values seen ('Male','Female'). ENUM keeps
--                    it tight, though VARCHAR would also work. We are
--                    intentionally NOT normalizing this into its own
--                    lookup table — with only 2 fixed values, ENUM is
--                    simpler and there's no real "lookup table" value
--                    being added (no extra attributes to hang off it).
--   height/weight-> CSV stores whole numbers (cm, kg) — SMALLINT is
--                    plenty and avoids unnecessary decimal storage.
--   bmi          -> CSV has one decimal place (e.g. 50.4) -> DECIMAL(4,1)
--                    is exact (no floating point rounding surprises,
--                    which matters for health metrics).
--   city         -> Free text, but includes the literal string
--                    'Unknown' for missing city data. We store this
--                    as NULL instead of leaving the string 'Unknown'
--                    in the table -- a NULL clearly says "we don't
--                    know this," while a stored string 'Unknown'
--                    invites bugs (e.g. someone grouping by city and
--                    getting a fake "Unknown" city with 400+ patients
--                    in it, or a literal city named "Unknown" being
--                    impossible to distinguish from missing data).
--   billing      -> CSV shows values like 2995.0, up to ~12,467.50.
--                    DECIMAL(8,2) is the correct type for money --
--                    never use FLOAT/DOUBLE for currency.
--   dates        -> last_visit_date is a real DATE (CSV format is
--                    already YYYY-MM-DD, MySQL's native format).
--   flag         -> Preventive_Care_Flag is 0/1 in the CSV -> BOOLEAN
--                    (MySQL stores this as TINYINT(1) under the hood,
--                    same idea as the CSV's 0/1).
-- =====================================================================

USE patient_data;

CREATE TABLE IF NOT EXISTS patients (
    patient_id               CHAR(6)         PRIMARY KEY,
    age                      TINYINT UNSIGNED NOT NULL,
    gender                   ENUM('Male','Female') NOT NULL,
    state_id                 TINYINT UNSIGNED NOT NULL,
    city                     VARCHAR(50)     NULL,   -- NULL = unknown (see note above)
    height_cm                SMALLINT UNSIGNED NOT NULL,
    weight_kg                SMALLINT UNSIGNED NOT NULL,
    bmi                      DECIMAL(4,1)    NOT NULL,
    insurance_type_id        TINYINT UNSIGNED NOT NULL,
    condition_id             TINYINT UNSIGNED NULL,  -- NULL = no primary condition on record
    num_chronic_conditions   TINYINT UNSIGNED NOT NULL,
    annual_visits            SMALLINT UNSIGNED NOT NULL,
    avg_billing_amount       DECIMAL(8,2)    NOT NULL,
    last_visit_date          DATE            NOT NULL,
    days_since_last_visit    SMALLINT UNSIGNED NOT NULL,
    preventive_care_flag     BOOLEAN         NOT NULL DEFAULT FALSE,

    CONSTRAINT fk_patients_state
        FOREIGN KEY (state_id) REFERENCES states(state_id),

    CONSTRAINT fk_patients_insurance
        FOREIGN KEY (insurance_type_id) REFERENCES insurance_types(insurance_type_id),

    CONSTRAINT fk_patients_condition
        FOREIGN KEY (condition_id) REFERENCES conditions(condition_id)
);

-- Index note: state_id, insurance_type_id, and condition_id are all
-- foreign keys. MySQL (InnoDB) automatically creates an index on each
-- FK column, so we don't need to add those manually -- this matters
-- for join performance once this table has real data in it.
