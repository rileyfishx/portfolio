-- =====================================================================
-- NHL Report 02: Standings Ranked Within Each Division
-- =====================================================================
-- WHAT THIS SHOWS:
--   Same data as Report 01, but teams are ranked WITHIN their own
--   division rather than league-wide. Useful because playoff seeding
--   in the NHL is partly division-based -- the top 3 teams in each
--   division automatically qualify.
-- =====================================================================

USE nhl_data;
SELECT
    t.conference,
    t.division,
    t.team_abbrev,
    t.team_name,
    s.points,
    s.wins,
    s.losses,
    s.ot_losses,
    (s.wins + s.losses + s.ot_losses)                   AS games_played,
    ROUND(s.wins / (s.wins + s.losses + s.ot_losses), 3) AS win_pct,
    -- rank within the division (resets to 1 for each new division)
    RANK() OVER (
        PARTITION BY t.division
        ORDER BY s.points DESC
    )                                                    AS division_rank
FROM standings s
JOIN teams t ON t.team_id = s.team_id
WHERE s.standings_date = (
    SELECT MAX(standings_date)
    FROM standings
    WHERE team_id = s.team_id
)
ORDER BY t.conference, t.division, division_rank;
