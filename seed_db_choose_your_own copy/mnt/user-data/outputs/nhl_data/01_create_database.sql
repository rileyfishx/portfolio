-- =====================================================================
-- 01_create_database.sql
-- =====================================================================
-- WHY THIS SCRIPT EXISTS:
-- This is project_two's database, fully separate from patient_data.
-- Same reasoning as the other project: separate domain, separate
-- schema, separate access scope.
-- =====================================================================

CREATE DATABASE IF NOT EXISTS nhl_data
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE nhl_data;
