-- =====================================================================
-- NHL Report 04: Team Home vs Away Win Record
-- =====================================================================
-- WHAT THIS SHOWS:
--   For each team, how many home games they won vs lost, and how many
--   away games they won vs lost. Helps answer "is this team better at
--   home?" -- a classic hockey analysis question.
--
-- HOW IT WORKS:
--   We build two separate subqueries (home_stats and away_stats) that
--   count wins/losses from each perspective, then JOIN them together
--   on team_id for the final side-by-side view.
-- =====================================================================

USE nhl_data;

WITH home_stats AS (
    SELECT
        g.home_team_id                                         AS team_id,
        COUNT(*)                                               AS home_games,
        SUM(CASE WHEN g.home_score > g.away_score THEN 1 ELSE 0 END) AS home_wins,
        SUM(CASE WHEN g.home_score < g.away_score THEN 1 ELSE 0 END) AS home_losses
    FROM games g
    WHERE g.game_state = 'OFF'
    GROUP BY g.home_team_id
),
away_stats AS (
    SELECT
        g.away_team_id                                         AS team_id,
        COUNT(*)                                               AS away_games,
        SUM(CASE WHEN g.away_score > g.home_score THEN 1 ELSE 0 END) AS away_wins,
        SUM(CASE WHEN g.away_score < g.home_score THEN 1 ELSE 0 END) AS away_losses
    FROM games g
    WHERE g.game_state = 'OFF'
    GROUP BY g.away_team_id
)
SELECT
    t.team_abbrev,
    t.team_name,
    t.division,
    -- home record
    COALESCE(h.home_games,  0) AS home_games,
    COALESCE(h.home_wins,   0) AS home_wins,
    COALESCE(h.home_losses, 0) AS home_losses,
    -- away record
    COALESCE(a.away_games,  0) AS away_games,
    COALESCE(a.away_wins,   0) AS away_wins,
    COALESCE(a.away_losses, 0) AS away_losses,
    -- home win % vs away win %
    CASE
        WHEN COALESCE(h.home_games, 0) = 0 THEN NULL
        ELSE ROUND(h.home_wins / h.home_games, 3)
    END                        AS home_win_pct,
    CASE
        WHEN COALESCE(a.away_games, 0) = 0 THEN NULL
        ELSE ROUND(a.away_wins / a.away_games, 3)
    END                        AS away_win_pct
FROM teams t
LEFT JOIN home_stats h ON h.team_id = t.team_id
LEFT JOIN away_stats a ON a.team_id = t.team_id
ORDER BY t.team_abbrev;
