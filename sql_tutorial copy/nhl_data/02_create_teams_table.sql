-- =====================================================================
-- 02_create_teams_table.sql
-- =====================================================================
-- WHY THIS SCRIPT EXISTS:
-- Looking at the notebook's actual output, every other piece of NHL
-- data (scores, standings, rosters, games) refers back to a TEAM via
-- its abbreviation (e.g. 'CAR', 'VGK', 'COL'). A team itself is the
-- one thing in this whole dataset that barely changes -- teams don't
-- get added or removed mid-season. That makes "teams" the natural
-- anchor table everything else hangs off of.
--
-- Compare this to standings or scores, which change constantly (every
-- night, every game) -- that's the signal that those belong in their
-- OWN tables rather than being crammed into this one. A table should
-- hold things that change together, at the same rate, for the same
-- reason. Team identity and nightly standings change for completely
-- different reasons and at completely different speeds, so they get
-- separated.
--
-- Fields chosen based on what get_standings()/get_live_scores() in the
-- notebook actually reference: team['teamAbbrev']['default'] is the
-- only team identifier the code currently uses. We add a couple of
-- obvious descriptive fields (full name, conference/division) since
-- they're standard, low-volatility attributes of a team and the NHL
-- API does expose them on team/standings objects -- but the strict
-- minimum needed to support the existing code is just team_abbrev.
-- =====================================================================

USE nhl_data;

CREATE TABLE IF NOT EXISTS teams (
    team_id      SMALLINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    team_abbrev  CHAR(3)      NOT NULL UNIQUE,   -- e.g. 'CAR', 'VGK', 'COL'
    team_name    VARCHAR(50)  NULL,              -- e.g. 'Carolina Hurricanes'
    conference   VARCHAR(20)  NULL,               -- e.g. 'Eastern'
    division     VARCHAR(20)  NULL                -- e.g. 'Metropolitan'
);

-- VERIFY BEFORE SEEDING:
-- team_name/conference/division aren't directly used in the notebook's
-- current code, so before writing a load script for them, fetch one
-- real response from /v1/standings/now and confirm the exact key
-- names the API returns for these fields -- API field names can drift
-- across versions, and we have not been able to verify a live response
-- from this environment.
