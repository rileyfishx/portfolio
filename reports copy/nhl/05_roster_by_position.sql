-- =====================================================================
-- NHL Report 05: Full Roster Breakdown by Team and Position
-- =====================================================================
-- WHAT THIS SHOWS:
--   Every player on every team's roster for the stored season, with
--   their position and age calculated from birth_date. Good for
--   exploring team composition and filtering by position.
-- =====================================================================

USE nhl_data;

SELECT
    t.team_abbrev,
    t.team_name,
    t.division,
    r.season,
    p.player_id,
    p.first_name,
    p.last_name,
    CONCAT(p.first_name, ' ', p.last_name)          AS full_name,
    p.position,
    p.birth_date,
    -- age = current year minus birth year, adjusted if birthday hasn't passed yet
    TIMESTAMPDIFF(YEAR, p.birth_date, CURDATE())    AS age
FROM rosters r
JOIN teams   t ON t.team_id   = r.team_id
JOIN players p ON p.player_id = r.player_id
ORDER BY t.team_abbrev, p.position, p.last_name;
