-- =====================================================================
-- 01_create_database.sql
-- =====================================================================
-- WHY THIS SCRIPT EXISTS:
-- This is project_one's database. It's completely separate from the
-- nhl_data database — different domain, different schema, different
-- access scope. Each project gets its own database so credentials and
-- table namespaces never collide.
--
-- We run this once, by itself, before touching any tables.
-- =====================================================================

CREATE DATABASE IF NOT EXISTS patient_data
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

-- utf8mb4 (not plain utf8) because MySQL's "utf8" is a legacy 3-byte
-- encoding that can't store the full Unicode range. utf8mb4 is the
-- correct modern default — worth knowing since "utf8" in MySQL is a
-- famous gotcha.

USE patient_data;
