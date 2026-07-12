-- =====================================================================
-- Healthcare Report 01: Full Patient Overview
-- =====================================================================
-- WHAT THIS SHOWS:
--   One row per patient with all their details, lookup codes resolved
--   to readable names (e.g. state code instead of state_id, condition
--   name instead of condition_id). This is the "master export" -- a
--   flat file with everything in one place for further analysis.
--
-- WHY WE JOIN THE LOOKUP TABLES:
--   The patients table stores state_id, insurance_type_id, condition_id
--   as small integer codes to avoid repeating text thousands of times.
--   These JOINs swap those codes back out for the human-readable names.
-- =====================================================================

USE patient_data;

SELECT
    p.patient_id,
    p.age,
    p.gender,
    st.state_code,
    p.city,
    p.height_cm,
    p.weight_kg,
    p.bmi,
    it.type_name                                AS insurance_type,
    COALESCE(c.condition_name, 'None on record') AS primary_condition,
    p.num_chronic_conditions,
    p.annual_visits,
    p.avg_billing_amount,
    p.last_visit_date,
    p.days_since_last_visit,
    -- convert the 0/1 flag to a Yes/No for readability in Excel
    CASE WHEN p.preventive_care_flag = 1 THEN 'Yes' ELSE 'No' END AS preventive_care
FROM patients p
JOIN states          st ON st.state_id          = p.state_id
JOIN insurance_types it ON it.insurance_type_id  = p.insurance_type_id
LEFT JOIN conditions  c  ON c.condition_id        = p.condition_id
-- LEFT JOIN for conditions because ~25% of patients have no condition (NULL)
-- an INNER JOIN would silently drop those 495 patients from the results
ORDER BY p.patient_id;
