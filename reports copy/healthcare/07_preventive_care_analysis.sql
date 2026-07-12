-- =====================================================================
-- Healthcare Report 07: Preventive Care Adoption Analysis
-- =====================================================================
-- WHAT THIS SHOWS:
--   Compares patients who use preventive care vs those who don't across
--   key metrics (billing, visits, chronic conditions). The goal is to
--   see whether preventive care patients cost less and stay healthier
--   -- a common hypothesis in population health management.
--
-- GOOD QUESTION THIS ANSWERS:
--   "Is investing in preventive care actually saving money?"
-- =====================================================================

USE patient_data;

-- Part 1: head-to-head comparison of preventive vs non-preventive
SELECT
    CASE WHEN p.preventive_care_flag = 1 THEN 'Uses Preventive Care'
         ELSE 'No Preventive Care'
    END                                         AS care_group,
    COUNT(p.patient_id)                         AS patient_count,
    ROUND(AVG(p.age), 1)                        AS avg_age,
    ROUND(AVG(p.bmi), 1)                        AS avg_bmi,
    ROUND(AVG(p.num_chronic_conditions), 2)     AS avg_chronic_conditions,
    ROUND(AVG(p.annual_visits), 2)              AS avg_annual_visits,
    ROUND(AVG(p.avg_billing_amount), 2)         AS avg_billing_amount,
    ROUND(AVG(p.days_since_last_visit), 0)      AS avg_days_since_last_visit
FROM patients p
GROUP BY p.preventive_care_flag
ORDER BY p.preventive_care_flag DESC;

-- =====================================================================
-- Part 2: preventive care rate broken down by insurance type
--   (run this separately or scroll down in the results)
-- =====================================================================
SELECT
    it.type_name                                AS insurance_type,
    COUNT(p.patient_id)                         AS total_patients,
    SUM(p.preventive_care_flag)                 AS preventive_care_users,
    ROUND(
        SUM(p.preventive_care_flag) / COUNT(p.patient_id) * 100,
        1
    )                                           AS preventive_care_pct,
    ROUND(
        AVG(CASE WHEN p.preventive_care_flag = 1 THEN p.avg_billing_amount END),
        2
    )                                           AS avg_billing_preventive,
    ROUND(
        AVG(CASE WHEN p.preventive_care_flag = 0 THEN p.avg_billing_amount END),
        2
    )                                           AS avg_billing_no_preventive
FROM patients p
JOIN insurance_types it ON it.insurance_type_id = p.insurance_type_id
GROUP BY it.insurance_type_id, it.type_name
ORDER BY preventive_care_pct DESC;
