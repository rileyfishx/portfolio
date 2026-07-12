-- =====================================================================
-- NHL Report 03: Game Results with Team Names
-- =====================================================================
-- WHAT THIS SHOWS:
--   Every completed game (state = 'OFF') with the home and away team
--   names filled in, the final score, and who won. Great for browsing
--   results or filtering by team/date range in Excel after exporting.
--
-- NOTE: This query joins teams TWICE (once for home, once for away)
--   because each game involves two different teams. You'll see two
--   separate JOIN lines -- one aliased as 'home', one as 'away'.
-- =====================================================================

USE nhl_data;

SELECT
    g.game_pk,
    g.game_date,
    home.team_abbrev                          AS home_team,
    home.team_name                            AS home_team_name,
    away.team_abbrev                          AS away_team,
    away.team_name                            AS away_team_name,
    g.home_score,
    g.away_score,
    -- determine the winner based on score comparison
    CASE
        WHEN g.home_score > g.away_score THEN home.team_abbrev
        WHEN g.away_score > g.home_score THEN away.team_abbrev
        ELSE 'TIE'
    END                                       AS winner,
    -- margin of victory
    ABS(CAST(g.home_score AS signed) - CAST(g.away_score AS signed))          AS goal_margin
FROM games g
JOIN teams home ON home.team_id = g.home_team_id
JOIN teams away ON away.team_id = g.away_team_id
-- only finished games have meaningful scores
WHERE g.game_state = 'OFF'
ORDER BY g.game_date DESC, g.game_pk;
