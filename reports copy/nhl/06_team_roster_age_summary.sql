-- =====================================================================
-- NHL Report 06: Team Roster Age Summary
-- =====================================================================
-- WHAT THIS SHOWS:
--   For each team, the average age of their roster, youngest player,
--   oldest player, and total roster size. Useful for comparing whether
--   a team is built around veterans or younger talent.
-- =====================================================================

USE nhl_data;

SELECT
    t.team_abbrev,
    t.team_name,
    t.division,
    r.season,
    COUNT(p.player_id)                                          AS roster_size,
    ROUND(AVG(TIMESTAMPDIFF(YEAR, p.birth_date, CURDATE())), 1) AS avg_age,
    MIN(TIMESTAMPDIFF(YEAR, p.birth_date, CURDATE()))           AS youngest_player_age,
    MAX(TIMESTAMPDIFF(YEAR, p.birth_date, CURDATE()))           AS oldest_player_age,
    -- names of the youngest and oldest players (using subqueries)
    (
        SELECT CONCAT(p2.first_name, ' ', p2.last_name)
        FROM players p2
        JOIN rosters r2 ON r2.player_id = p2.player_id
        WHERE r2.team_id = t.team_id AND r2.season = r.season
        ORDER BY p2.birth_date DESC
        LIMIT 1
    )                                                           AS youngest_player,
    (
        SELECT CONCAT(p3.first_name, ' ', p3.last_name)
        FROM players p3
        JOIN rosters r3 ON r3.player_id = p3.player_id
        WHERE r3.team_id = t.team_id AND r3.season = r.season
        ORDER BY p3.birth_date ASC
        LIMIT 1
    )                                                           AS oldest_player
FROM rosters r
JOIN teams   t ON t.team_id   = r.team_id
JOIN players p ON p.player_id = r.player_id
WHERE p.birth_date IS NOT NULL
GROUP BY t.team_id, t.team_abbrev, t.team_name, t.division, r.season
ORDER BY avg_age DESC;
