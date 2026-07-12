-- =====================================================================
-- 07_add_constraints.sql
-- =====================================================================
-- WHY THIS SCRIPT EXISTS:
-- Same idea as the patient_data constraints script -- the column types
-- alone don't stop nonsensical values from being inserted. A team
-- can't have negative wins. A game can't have a negative score. This
-- script closes those gaps with CHECK constraints.
--
-- Run this AFTER 06_create_rosters_table.sql -- all six tables must
-- exist first since this script alters several of them.
-- =====================================================================

USE nhl_data;

ALTER TABLE standings
    ADD CONSTRAINT chk_standings_points
        CHECK (points >= 0),
    ADD CONSTRAINT chk_standings_wins
        CHECK (wins >= 0),
    ADD CONSTRAINT chk_standings_losses
        CHECK (losses >= 0),
    ADD CONSTRAINT chk_standings_ot_losses
        CHECK (ot_losses >= 0);

ALTER TABLE games
    ADD CONSTRAINT chk_games_home_score
        CHECK (home_score IS NULL OR home_score >= 0),
    ADD CONSTRAINT chk_games_away_score
        CHECK (away_score IS NULL OR away_score >= 0),
    -- A team can't play itself. This catches a data entry mistake
    -- where the same team_id accidentally ends up as both the home
    -- and away team for one game.
    ADD CONSTRAINT chk_games_different_teams
        CHECK (home_team_id <> away_team_id);

-- NOTE: home_score/away_score allow NULL (see 04_create_games_table.sql
-- -- a game that hasn't started yet has no score), so the CHECK has
-- to explicitly allow NULL through with "IS NULL OR ..." -- otherwise
-- the constraint would incorrectly reject every not-yet-played game.

-- NOTE ON MySQL VERSIONS: same as patient_data -- CHECK constraints
-- require MySQL 8.0.16 or later to actually be enforced. Run
-- SELECT VERSION(); to confirm if you're unsure.
