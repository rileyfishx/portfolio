"""
load_nhl.py
===========
WHY THIS SCRIPT EXISTS:
The CREATE TABLE scripts (01-06) only build empty table structure.
This script calls the same functions defined in nhl.ipynb against the
LIVE NHL API and inserts the results into the nhl_data database.

IMPORTANT -- READ BEFORE RUNNING:
This script needs real internet access to api-web.nhle.com, so it must
be run from your own machine (not a sandboxed environment). It pulls
whatever is happening RIGHT NOW -- live scores and current standings
-- so your results will differ depending on the day/time you run it
(during the off-season, get_live_scores() will return no games, which
is expected, not a bug).

WHAT THIS SCRIPT LOADS, AND WHY EACH PART IS HANDLED THE WAY IT IS:

  1. STANDINGS -- fully reliable. The notebook's __main__ block already
     prints exactly these fields (teamAbbrev, points, wins, losses,
     otLosses), so we know this JSON shape is correct and tested.

  2. LIVE SCORES / GAMES -- mostly reliable. The notebook's __main__
     block confirms homeTeam/awayTeam/abbrev/score/gameState. The one
     thing NOT confirmed is the literal game ID field name (the
     notebook never prints it) -- this script tries the most common
     NHL API field names for it ("id", then "gamePk" as a fallback)
     and will tell you clearly if neither is found, rather than
     silently inserting a wrong or made-up ID.

  3. ROSTERS / PLAYERS -- NOT verified against a live response in this
     project (the schema-creation scripts flagged this same caveat).
     This script includes a function for it, but treats it as
     "attempt and report" -- if the live JSON field names differ from
     what's coded here, you'll see a clear error telling you which
     field was missing, so you can adjust the field name and re-run
     rather than getting bad data silently inserted.

REQUIREMENTS:
  pip3 install requests mysql-connector-python

USAGE:
  python3 load_nhl.py
"""

import sys
import requests
import mysql.connector
from datetime import date

# ---------------------------------------------------------------------
# CONFIG -- adjust if your setup differs
# ---------------------------------------------------------------------
DB_CONFIG = {
    "host": "localhost",
    "user": "root",
    "password": "",   # fill in your MySQL root password here
    "database": "nhl_data",
}

BASE_URL = "https://api-web.nhle.com/v1"


# ---------------------------------------------------------------------
# These functions are copied directly from nhl.ipynb so this script
# can run standalone without needing to execute the notebook itself.
# ---------------------------------------------------------------------
def get(endpoint):
    response = requests.get(f"{BASE_URL}/{endpoint}")
    response.raise_for_status()
    return response.json()


def get_standings():
    return get("standings/now")


def get_live_scores():
    return get("score/now")


def get_team_roster(team_abbrev, season="20242025"):
    return get(f"roster/{team_abbrev}/{season}")


def get_player(player_id):
    return get(f"player/{player_id}/landing")


# ---------------------------------------------------------------------
# Database helpers
# ---------------------------------------------------------------------
def connect():
    try:
        return mysql.connector.connect(**DB_CONFIG)
    except mysql.connector.Error as err:
        print(f"Could not connect to MySQL: {err}")
        print("Check that MySQL is running (brew services start mysql)")
        print("and that DB_CONFIG above has the correct password.")
        sys.exit(1)


def get_or_create_team(cursor, abbrev):
    """Look up a team's internal team_id by abbreviation, inserting a
    new row if this is the first time we've seen this team. Returns
    the team_id.

    This pattern (look up, insert if missing, return the id) is the
    standard way to populate a dimension table -- like teams -- from
    streaming/live data where you don't know the full list of teams
    ahead of time the way we did with patient_data's fixed lookup
    values.
    """
    cursor.execute("SELECT team_id FROM teams WHERE team_abbrev = %s", (abbrev,))
    row = cursor.fetchone()
    if row:
        return row[0]

    cursor.execute("INSERT INTO teams (team_abbrev) VALUES (%s)", (abbrev,))
    return cursor.lastrowid


def load_standings(cursor):
    print("Fetching standings ...")
    data = get_standings()
    teams = data.get("standings", [])
    today = date.today().isoformat()

    inserted = 0
    for team in teams:
        abbrev = team["teamAbbrev"]["default"]
        team_id = get_or_create_team(cursor, abbrev)

        cursor.execute(
            """
            INSERT IGNORE INTO standings
                (team_id, standings_date, points, wins, losses, ot_losses)
            VALUES (%s, %s, %s, %s, %s, %s)
            """,
            (team_id, today, team["points"], team["wins"], team["losses"], team["otLosses"]),
        )
        inserted += cursor.rowcount

    print(f"  {len(teams)} teams in standings, {inserted} new standings rows inserted.")
    print("  (Re-running on the same day will correctly insert 0 new rows --")
    print("   the UNIQUE constraint on (team_id, standings_date) prevents duplicate")
    print("   snapshots for the same day.)")


def load_games(cursor):
    print("Fetching live/recent scores ...")
    data = get_live_scores()
    games = data.get("games", [])

    if not games:
        print("  No games returned (this is expected during the off-season")
        print("  or on a day with no scheduled games).")
        return

    inserted = 0
    skipped = 0
    for game in games:
        home = game["homeTeam"]
        away = game["awayTeam"]
        home_team_id = get_or_create_team(cursor, home["abbrev"])
        away_team_id = get_or_create_team(cursor, away["abbrev"])

        # The notebook's printed output never showed a literal game ID
        # field, so we try the two most common NHL API field names for
        # it and fail clearly if neither is present -- see module
        # docstring above.
        game_pk = game.get("id") or game.get("gamePk")
        if game_pk is None:
            print(f"  SKIPPED a game: no 'id' or 'gamePk' field found.")
            print(f"  Raw keys available on this game object: {list(game.keys())}")
            print(f"  Add the correct field name to this script (see load_games()) and re-run.")
            skipped += 1
            continue

        cursor.execute(
            """
            INSERT INTO games
                (game_pk, game_date, home_team_id, away_team_id,
                 home_score, away_score, game_state)
            VALUES (%s, %s, %s, %s, %s, %s, %s)
            ON DUPLICATE KEY UPDATE
                home_score = VALUES(home_score),
                away_score = VALUES(away_score),
                game_state = VALUES(game_state)
            """,
            (
                game_pk, date.today().isoformat(), home_team_id, away_team_id,
                home.get("score"), away.get("score"), game.get("gameState"),
            ),
        )
        inserted += 1

    print(f"  {inserted} games loaded/updated, {skipped} skipped.")


def load_team_roster(cursor, team_abbrev, season="20242025"):
    """Loads one team's roster for one season. Not called automatically
    by main() below -- roster/player field names are NOT verified
    against a live response (see module docstring), so this is meant
    to be run and checked manually first:

        from load_nhl import connect, load_team_roster
        conn = connect()
        cur = conn.cursor()
        load_team_roster(cur, "TOR")
        conn.commit()

    If this raises a KeyError, the printed message will tell you which
    field name didn't match -- check the raw response with:

        import json
        print(json.dumps(get_team_roster("TOR"), indent=2)[:2000])

    and adjust the field names in this function accordingly.
    """
    print(f"Fetching roster for {team_abbrev}, season {season} ...")
    data = get_team_roster(team_abbrev, season)
    team_id = get_or_create_team(cursor, team_abbrev)

    # NHL roster responses are commonly grouped by position group
    # (forwards/defensemen/goalies) rather than one flat list -- this
    # combines all three if present. VERIFY this matches the real
    # response shape before trusting the results.
    all_players = []
    for group in ("forwards", "defensemen", "goalies"):
        all_players.extend(data.get(group, []))

    if not all_players:
        print(f"  No players found. Raw top-level keys: {list(data.keys())}")
        print("  The response shape doesn't match what this function expects --")
        print("  inspect the raw JSON and adjust load_team_roster() accordingly.")
        return

    inserted = 0
    for player in all_players:
        player_id = player["id"]
        first_name = player["firstName"]["default"]
        last_name = player["lastName"]["default"]
        position = player.get("positionCode")
        birth_date = player.get("birthDate")

        cursor.execute(
            """
            INSERT INTO players (player_id, first_name, last_name, position, birth_date)
            VALUES (%s, %s, %s, %s, %s)
            ON DUPLICATE KEY UPDATE
                first_name = VALUES(first_name),
                last_name = VALUES(last_name),
                position = VALUES(position),
                birth_date = VALUES(birth_date)
            """,
            (player_id, first_name, last_name, position, birth_date),
        )

        cursor.execute(
            """
            INSERT IGNORE INTO rosters (team_id, player_id, season)
            VALUES (%s, %s, %s)
            """,
            (team_id, player_id, season),
        )
        inserted += 1

    print(f"  {inserted} players loaded for {team_abbrev} ({season}).")


def main():
    conn = connect()
    cursor = conn.cursor()

    load_standings(cursor)
    conn.commit()

    load_games(cursor)
    conn.commit()

    print()
    print("Standings and games loaded.")
    print("Roster/player loading was NOT run automatically -- see the")
    print("load_team_roster() docstring in this file for why, and how")
    print("to run it manually for one team at a time.")

    cursor.close()
    conn.close()


if __name__ == "__main__":
    main()
