-- =====================================================================
-- Healthcare Report 04: Patient Summary by State
-- =====================================================================
-- WHAT THIS SHOWS:
--   For each of the 10 states in the dataset, a summary of patient
--   volume, average billing, most common condition, and preventive
--   care adoption rate. Useful for geographic comparisons.
--
-- GOOD QUESTION THIS ANSWERS:
--   "Which states have the highest-cost patients? Which states have
--   the highest preventive care usage?"
-- =====================================================================

USE patient_data;

SELECT
    st.state_code,
    COUNT(p.patient_id)                                          AS patient_count,
    ROUND(AVG(p.age), 1)                                         AS avg_age,
    ROUND(AVG(p.bmi), 1)                                         AS avg_bmi,
    ROUND(AVG(p.num_chronic_conditions), 2)                      AS avg_chronic_conditions,
    ROUND(AVG(p.annual_visits), 2)                               AS avg_annual_visits,
    ROUND(AVG(p.avg_billing_amount), 2)                          AS avg_billing_amount,
    ROUND(SUM(p.avg_billing_amount), 2)                          AS total_billing,
    ROUND(
        SUM(p.preventive_care_flag) / COUNT(p.patient_id) * 100,
        1
    )                                                            AS preventive_care_pct,
    -- most common condition in this state (using a correlated subquery)
    (
        SELECT COALESCE(c2.condition_name, 'None on record')
        FROM patients p2
        LEFT JOIN conditions c2 ON c2.condition_id = p2.condition_id
        WHERE p2.state_id = st.state_id
        GROUP BY p2.condition_id
        ORDER BY COUNT(*) DESC
        LIMIT 1
    )                                                            AS most_common_condition
FROM patients p
JOIN states st ON st.state_id = p.state_id
GROUP BY st.state_id, st.state_code
ORDER BY patient_count DESC;
