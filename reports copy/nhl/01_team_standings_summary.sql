-- =====================================================================
-- NHL Report 01: Team Standings Summary
-- =====================================================================
-- WHAT THIS SHOWS:
--   The most recent standings snapshot for every team, ranked by points.
--   This is the "league table" view -- good for seeing where each team
--   sits right now and how their win/loss record breaks down.
--
-- HOW TO EXPORT AS CSV IN WORKBENCH:
--   1. Run this query (lightning bolt button or Ctrl+Shift+Enter)
--   2. In the result grid, click the small export icon (looks like a grid
--      with an arrow) at the top of the results panel
--   3. Choose "Export recordset to an external file"
--   4. Pick CSV format, choose your folder, click Save
-- =====================================================================

USE nhl_data;

SELECT
    t.team_abbrev,
    t.team_name,
    t.conference,
    t.division,
    s.standings_date,
    s.points,
    s.wins,
    s.losses,
    s.ot_losses,
    -- games played = wins + losses + OT losses
    (s.wins + s.losses + s.ot_losses)          AS games_played,
    -- win percentage = wins / games played, rounded to 3 decimal places
    ROUND(s.wins / (s.wins + s.losses + s.ot_losses), 3) AS win_pct,
    -- rank within the full league by points (ties share the same rank)
    RANK() OVER (PARTITION BY t.conference ORDER BY s.points DESC)        AS league_rank
FROM standings s
JOIN teams t ON t.team_id = s.team_id
-- keep only the latest date for each team
WHERE s.standings_date = (
    SELECT MAX(standings_date)
    FROM standings
    WHERE team_id = s.team_id
)
ORDER BY league_rank;
