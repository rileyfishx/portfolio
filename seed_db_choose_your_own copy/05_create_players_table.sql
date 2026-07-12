-- =====================================================================
-- 05_create_players_table.sql
-- =====================================================================
-- WHY THIS SCRIPT EXISTS:
-- get_player(player_id) in the notebook pulls individual player detail
-- ("landing" data -- typically bio info: name, position, birth date,
-- etc.). A player is its own entity, separate from any one team,
-- because players change teams (trades, free agency) but their core
-- identity (name, birth date, position) doesn't change when that
-- happens. That's the cue to give players their own table rather than
-- folding player info into the roster table.
--
-- We use the NHL's own player ID as the primary key for the same
-- reason we did this for games: get_player(player_id) and
-- get_team_roster() both reference players by this exact ID already.
-- =====================================================================

USE nhl_data;

CREATE TABLE IF NOT EXISTS players (
    player_id    INT UNSIGNED PRIMARY KEY,   -- NHL's own player ID, used as-is
    first_name   VARCHAR(50)  NOT NULL,
    last_name    VARCHAR(50)  NOT NULL,
    position     VARCHAR(5)   NULL,           -- e.g. 'C', 'LW', 'D', 'G'
    birth_date   DATE         NULL
);

-- VERIFY BEFORE SEEDING:
-- get_player()'s exact JSON keys (commonly firstName/lastName as
-- nested {"default": "..."} objects in this API family, plus
-- positionCode and birthDate) need confirming against a real response
-- before the load script is written -- not verified from this
-- environment.
