-- =====================================================================
-- NHL Report 07: Scoring Trends by Month
-- =====================================================================
-- WHAT THIS SHOWS:
--   Average goals per game, total goals, and number of games played
--   grouped by month. Good for spotting whether scoring goes up or
--   down as the season progresses (teams often tighten defensively
--   in the playoffs, for example).
-- =====================================================================

USE nhl_data;

SELECT
    YEAR(g.game_date)                                           AS game_year,
    MONTH(g.game_date)                                          AS game_month,
    -- readable month name (e.g. 'October', 'November')
    MONTHNAME(g.game_date)                                      AS month_name,
    COUNT(*)                                                    AS games_played,
    SUM(g.home_score + g.away_score)                            AS total_goals,
    ROUND(AVG(g.home_score + g.away_score), 2)                  AS avg_goals_per_game,
    ROUND(AVG(g.home_score), 2)                                 AS avg_home_score,
    ROUND(AVG(g.away_score), 2)                                 AS avg_away_score,
    -- how often the home team wins that month
    ROUND(
        SUM(CASE WHEN g.home_score > g.away_score THEN 1 ELSE 0 END) / COUNT(*),
        3
    )                                                           AS home_win_rate
FROM games g
WHERE g.game_state = 'OFF'
GROUP BY game_year, game_month, month_name
ORDER BY game_year, game_month;
