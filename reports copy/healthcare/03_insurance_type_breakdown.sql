-- =====================================================================
-- Healthcare Report 03: Patient Breakdown by Insurance Type
-- =====================================================================
-- WHAT THIS SHOWS:
--   For each insurance type (Medicaid, Medicare, Private, Self-Pay),
--   how many patients are covered, their average billing, and what
--   share of the total patient population they represent.
--
-- GOOD QUESTION THIS ANSWERS:
--   "Do self-pay patients cost more per visit? Are Medicare patients
--   older on average?" -- useful for understanding payer mix.
-- =====================================================================

USE patient_data;

SELECT
    it.type_name                                AS insurance_type,
    COUNT(p.patient_id)                         AS patient_count,
    ROUND(COUNT(p.patient_id) / (SELECT COUNT(*) FROM patients) * 100, 1)
                                                AS pct_of_total,
    ROUND(AVG(p.age), 1)                        AS avg_age,
    ROUND(AVG(p.num_chronic_conditions), 2)     AS avg_chronic_conditions,
    ROUND(AVG(p.annual_visits), 2)              AS avg_annual_visits,
    ROUND(AVG(p.avg_billing_amount), 2)         AS avg_billing_amount,
    -- what share of patients in each group use preventive care
    ROUND(
        SUM(p.preventive_care_flag) / COUNT(p.patient_id) * 100,
        1
    )                                           AS preventive_care_pct
FROM patients p
JOIN insurance_types it ON it.insurance_type_id = p.insurance_type_id
GROUP BY it.insurance_type_id, it.type_name
ORDER BY patient_count DESC;
