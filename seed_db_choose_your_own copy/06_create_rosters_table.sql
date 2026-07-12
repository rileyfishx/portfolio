-- =====================================================================
-- 06_create_rosters_table.sql
-- =====================================================================
-- WHY THIS SCRIPT EXISTS:
-- get_team_roster(team_abbrev, season) in the notebook is explicitly
-- season-scoped (the default argument is "20242025"). A single player
-- can appear on different teams' rosters across different seasons --
-- that's a many-to-many relationship (many players <-> many teams,
-- changing over time), which is exactly the situation a JOIN table is
-- built for. This table has no interesting data of its own -- it just
-- records WHICH player was on WHICH team for WHICH season.
--
-- This is why rosters must be created AFTER both players and teams --
-- it has foreign keys pointing to both.
-- =====================================================================

USE nhl_data;

CREATE TABLE IF NOT EXISTS rosters (
    roster_id   INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    team_id     SMALLINT UNSIGNED NOT NULL,
    player_id   INT UNSIGNED      NOT NULL,
    season      CHAR(8)           NOT NULL,  -- e.g. '20242025', matches API format

    CONSTRAINT fk_rosters_team
        FOREIGN KEY (team_id) REFERENCES teams(team_id),

    CONSTRAINT fk_rosters_player
        FOREIGN KEY (player_id) REFERENCES players(player_id),

    -- A given player should only appear once per team per season --
    -- prevents duplicate roster entries if a load script reruns.
    CONSTRAINT uq_roster_team_player_season
        UNIQUE (team_id, player_id, season)
);
