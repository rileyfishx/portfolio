-- =====================================================================
-- Healthcare Report 06: High-Risk Patient Identification
-- =====================================================================
-- WHAT THIS SHOWS:
--   Patients who meet multiple "high risk" criteria simultaneously --
--   high chronic condition count, high BMI, AND long gap since last
--   visit. These are the patients a care team would want to follow up
--   with most urgently.
--
-- HOW TO ADJUST THE THRESHOLDS:
--   Change the numbers in the WHERE clause to widen or narrow the list.
--   For example, change days_since_last_visit > 180 to > 90 to catch
--   patients who haven't been seen in just 3 months instead of 6.
-- =====================================================================

USE patient_data;

SELECT
    p.patient_id,
    p.age,
    p.gender,
    st.state_code,
    p.city,
    p.bmi,
    p.num_chronic_conditions,
    COALESCE(c.condition_name, 'None on record') AS primary_condition,
    it.type_name                                 AS insurance_type,
    p.annual_visits,
    p.avg_billing_amount,
    p.last_visit_date,
    p.days_since_last_visit,
    -- a simple risk score: 1 point per condition + 1 if BMI > 30 + 1 if long gap
    (
        p.num_chronic_conditions
        + CASE WHEN p.bmi > 30 THEN 1 ELSE 0 END
        + CASE WHEN p.days_since_last_visit > 180 THEN 1 ELSE 0 END
        + CASE WHEN p.annual_visits < 2 THEN 1 ELSE 0 END
    )                                            AS risk_score
FROM patients p
JOIN states          st ON st.state_id          = p.state_id
JOIN insurance_types it ON it.insurance_type_id  = p.insurance_type_id
LEFT JOIN conditions  c  ON c.condition_id        = p.condition_id
WHERE
    -- at least 3 chronic conditions
    p.num_chronic_conditions >= 3
    -- overweight (BMI above 30)
    AND p.bmi > 30
    -- haven't been seen in at least 6 months
    AND p.days_since_last_visit > 180
ORDER BY risk_score DESC, p.days_since_last_visit DESC;
