-- =====================================================================
-- 05_add_indexes.sql
-- =====================================================================
-- WHY THIS SCRIPT EXISTS:
-- An index is a separate, sorted lookup structure MySQL maintains
-- alongside a table -- it lets MySQL jump straight to matching rows
-- instead of scanning every row in the table (a "full table scan").
-- With only 2000 rows this barely matters for speed, but the
-- HABIT matters: the index choices below are deliberately tied to the
-- report queries in the tutorial, not added blindly. Indexing every
-- column "just in case" actually slows down INSERTs and wastes disk
-- space, since MySQL has to update every index on every write.
--
-- Foreign key columns (state_id, insurance_type_id, condition_id)
-- already have an automatic index from script 03 -- InnoDB does this
-- for every FK so joins against the lookup tables are fast by default.
-- The indexes below are for columns that are NOT foreign keys but ARE
-- commonly filtered/grouped/sorted on in reports.
--
-- Run this AFTER 04_add_constraints.sql (order doesn't strictly matter
-- between constraints and indexes, but running structure changes
-- before performance changes is a reasonable habit).
-- =====================================================================

USE patient_data;

-- Used by: "patients overdue for a checkup" reports, and any report
-- filtering or sorting by recency of last visit.
CREATE INDEX idx_patients_last_visit_date ON patients (last_visit_date);

-- Used by: "how many patients are flagged for preventive care" and
-- segmentation reports that split the population by this flag.
CREATE INDEX idx_patients_preventive_flag ON patients (preventive_care_flag);

-- Used by: billing/revenue reports that sort or filter on spend.
CREATE INDEX idx_patients_billing_amount ON patients (avg_billing_amount);

-- Composite index: many reports filter by state AND look at billing
-- or visit counts within that state. A composite index on (state_id,
-- avg_billing_amount) serves "patients in state X sorted by billing"
-- queries more efficiently than two separate single-column indexes,
-- because MySQL can use ONE index to satisfy both the filter and the
-- sort in a single pass.
CREATE INDEX idx_patients_state_billing ON patients (state_id, avg_billing_amount);

-- VERIFY INDEX USAGE:
-- Use EXPLAIN before a query to see whether MySQL actually chose to
-- use an index, e.g.:
--
--   EXPLAIN SELECT * FROM patients WHERE last_visit_date < '2025-06-01';
--
-- Look at the "key" column in the output -- if it names an index
-- (e.g. idx_patients_last_visit_date), the index is being used. If it
-- says NULL, MySQL decided a full table scan was cheaper (this can
-- legitimately happen on small tables like this one, where scanning
-- 2000 rows is already fast enough that the index doesn't help).
