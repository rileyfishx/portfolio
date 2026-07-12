-- =====================================================================
-- 03_create_standings_table.sql
-- =====================================================================
-- WHY THIS SCRIPT EXISTS:
-- Look at get_standings() in the notebook -- it returns points, wins,
-- losses, and otLosses PER TEAM, and this changes every single day a
-- game is played. If we stored these columns directly on the teams
-- table, every update would overwrite yesterday's standing with no
-- history -- you'd never be able to answer "what were the standings
-- on March 1st?"
--
-- So standings get their own table, with one row per (team, date)
-- combination. This is a classic "fact table that changes over time"
-- pattern -- the team is the stable dimension, the standing is a
-- time-stamped measurement against it.
--
-- Run this AFTER 02_create_teams_table.sql -- it has a FOREIGN KEY
-- back to teams.
-- =====================================================================

USE nhl_data;

CREATE TABLE IF NOT EXISTS standings (
    standing_id    INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    team_id        SMALLINT UNSIGNED NOT NULL,
    standings_date DATE               NOT NULL,  -- the day this snapshot was pulled
    points         SMALLINT UNSIGNED NOT NULL,
    wins           SMALLINT UNSIGNED NOT NULL,
    losses         SMALLINT UNSIGNED NOT NULL,
    ot_losses      SMALLINT UNSIGNED NOT NULL,

    CONSTRAINT fk_standings_team
        FOREIGN KEY (team_id) REFERENCES teams(team_id),

    -- A team should only have ONE standings row per day -- this
    -- prevents accidentally inserting duplicate snapshots if the
    -- load script is run twice on the same day.
    CONSTRAINT uq_standings_team_date
        UNIQUE (team_id, standings_date)
);
