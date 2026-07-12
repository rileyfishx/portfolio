-- =====================================================================
-- 04_create_games_table.sql
-- =====================================================================
-- WHY THIS SCRIPT EXISTS:
-- get_live_scores() and get_game() in the notebook deal with individual
-- games -- each one has a home team, an away team, a score for each,
-- and a state ('OFF' meaning finished, plus 'LIVE'/'FUT' etc. in the
-- live NHL API). A game involves TWO teams, which is why this table
-- has two separate foreign keys back to teams (home_team_id and
-- away_team_id) instead of one -- this is a common pattern any time a
-- table represents a relationship BETWEEN two rows of another table.
--
-- We use the NHL's own game_id as our primary key (game_pk) rather
-- than inventing our own auto-increment ID, because get_game(game_id)
-- in the notebook already references games by this exact ID -- reusing
-- it means our schema lines up with the API's own identifiers and we
-- never have to map back and forth between "our ID" and "their ID."
-- =====================================================================

USE nhl_data;

CREATE TABLE IF NOT EXISTS games (
    game_pk        BIGINT UNSIGNED PRIMARY KEY,  -- NHL's own game ID, used as-is
    game_date      DATE              NOT NULL,
    home_team_id   SMALLINT UNSIGNED NOT NULL,
    away_team_id   SMALLINT UNSIGNED NOT NULL,
    home_score     TINYINT UNSIGNED  NULL,        -- NULL until the game has started
    away_score     TINYINT UNSIGNED  NULL,
    game_state     VARCHAR(10)       NOT NULL,    -- e.g. 'OFF', 'LIVE', 'FUT'

    CONSTRAINT fk_games_home_team
        FOREIGN KEY (home_team_id) REFERENCES teams(team_id),

    CONSTRAINT fk_games_away_team
        FOREIGN KEY (away_team_id) REFERENCES teams(team_id)
);

-- VERIFY BEFORE SEEDING:
-- The notebook's __main__ block only prints scores -- it never shows a
-- raw game_id. get_game(game_id) implies game IDs exist somewhere in
-- the schedule/score payloads, but we have not seen a literal example
-- value from this environment (NHL network access is blocked here).
-- Confirm the actual key name/format (commonly "id" or "gamePk" in the
-- NHL API family) against a real response before writing the load
-- script for this table.
