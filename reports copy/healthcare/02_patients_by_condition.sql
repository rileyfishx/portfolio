-- =====================================================================
-- Healthcare Report 02: Patient Count and Billing by Condition
-- =====================================================================
-- WHAT THIS SHOWS:
--   How many patients have each primary condition, their average age,
--   average billing amount, and average number of annual visits.
--   The "None on record" row covers the ~25% of patients with no
--   primary condition listed.
--
-- GOOD QUESTION THIS ANSWERS:
--   "Which conditions are most common, and which cost the most to treat?"
-- =====================================================================

USE patient_data;

SELECT
    COALESCE(c.condition_name, 'None on record') AS primary_condition,
    COUNT(p.patient_id)                          AS patient_count,
    ROUND(COUNT(p.patient_id) / (SELECT COUNT(*) FROM patients) * 100, 1)
                                                 AS pct_of_total,
    ROUND(AVG(p.age), 1)                         AS avg_age,
    ROUND(AVG(p.bmi), 1)                         AS avg_bmi,
    ROUND(AVG(p.annual_visits), 1)               AS avg_annual_visits,
    ROUND(AVG(p.avg_billing_amount), 2)          AS avg_billing_amount,
    ROUND(MIN(p.avg_billing_amount), 2)          AS min_billing,
    ROUND(MAX(p.avg_billing_amount), 2)          AS max_billing
FROM patients p
LEFT JOIN conditions c ON c.condition_id = p.condition_id
GROUP BY c.condition_id, c.condition_name
ORDER BY patient_count DESC;
