-- =====================================================================
-- 08_add_indexes.sql
-- =====================================================================
-- WHY THIS SCRIPT EXISTS:
-- Same reasoning as patient_data's index script -- tied to actual
-- report queries, not added blindly. Foreign key columns (team_id,
-- home_team_id, away_team_id, player_id) already have automatic
-- indexes from the FOREIGN KEY constraints in scripts 03-06.
--
-- Run this AFTER 07_add_constraints.sql.
-- =====================================================================

USE nhl_data;

-- Used by: "standings as of a specific date" and "team's standing over
-- time" reports -- this is the natural way standings get queried,
-- since standings_date is not a foreign key but is filtered/sorted on
-- constantly.
CREATE INDEX idx_standings_date ON standings (standings_date);

-- Used by: "games on a given day" and schedule-style reports.
CREATE INDEX idx_games_date ON games (game_date);

-- Used by: filtering games by their state (e.g. only finished games,
-- or only currently live games).
CREATE INDEX idx_games_state ON games (game_state);

-- Composite index: roster reports are almost always "who was on team
-- X during season Y" -- a composite index on (team_id, season) serves
-- that exact filter pattern directly, rather than relying on the
-- team_id foreign key index alone and then scanning all of that
-- team's roster rows across every season to find the one you want.
CREATE INDEX idx_rosters_team_season ON rosters (team_id, season);

-- VERIFY INDEX USAGE the same way as patient_data:
--   EXPLAIN SELECT * FROM games WHERE game_date = '2026-01-15';
