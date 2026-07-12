-- =====================================================================
-- Healthcare Report 05: Patient Segmentation by Age Group
-- =====================================================================
-- WHAT THIS SHOWS:
--   Patients bucketed into clinical age groups (18-34, 35-49, etc.)
--   with health and billing metrics for each group. This is a classic
--   segmentation query -- you're grouping a continuous variable (age)
--   into meaningful categories using CASE WHEN.
--
-- GOOD QUESTION THIS ANSWERS:
--   "Are older patients costing more? Do younger patients visit less?"
-- =====================================================================

USE patient_data;

SELECT
    CASE
        WHEN p.age BETWEEN 18 AND 34 THEN '18-34 Young Adult'
        WHEN p.age BETWEEN 35 AND 49 THEN '35-49 Middle Age'
        WHEN p.age BETWEEN 50 AND 64 THEN '50-64 Pre-Senior'
        WHEN p.age BETWEEN 65 AND 79 THEN '65-79 Senior'
        ELSE '80+ Elderly'
    END                                             AS age_group,
    COUNT(p.patient_id)                             AS patient_count,
    ROUND(AVG(p.bmi), 1)                            AS avg_bmi,
    ROUND(AVG(p.num_chronic_conditions), 2)         AS avg_chronic_conditions,
    ROUND(AVG(p.annual_visits), 2)                  AS avg_annual_visits,
    ROUND(AVG(p.avg_billing_amount), 2)             AS avg_billing_amount,
    ROUND(AVG(p.days_since_last_visit), 0)          AS avg_days_since_last_visit,
    ROUND(
        SUM(p.preventive_care_flag) / COUNT(p.patient_id) * 100,
        1
    )                                               AS preventive_care_pct,
    -- most common insurance type per age group
    (
        SELECT it2.type_name
        FROM patients p2
        JOIN insurance_types it2 ON it2.insurance_type_id = p2.insurance_type_id
        WHERE p2.age BETWEEN
            CASE
                WHEN p.age BETWEEN 18 AND 34 THEN 18
                WHEN p.age BETWEEN 35 AND 49 THEN 35
                WHEN p.age BETWEEN 50 AND 64 THEN 50
                WHEN p.age BETWEEN 65 AND 79 THEN 65
                ELSE 80
            END
            AND
            CASE
                WHEN p.age BETWEEN 18 AND 34 THEN 34
                WHEN p.age BETWEEN 35 AND 49 THEN 49
                WHEN p.age BETWEEN 50 AND 64 THEN 64
                WHEN p.age BETWEEN 65 AND 79 THEN 79
                ELSE 120
            END
        GROUP BY p2.insurance_type_id
        ORDER BY COUNT(*) DESC
        LIMIT 1
    )                                               AS most_common_insurance
FROM patients p
GROUP BY age_group
ORDER BY MIN(p.age);
