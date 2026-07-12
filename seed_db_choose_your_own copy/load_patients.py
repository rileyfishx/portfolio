"""
load_patients.py
=================
WHY THIS SCRIPT EXISTS:
The CREATE TABLE scripts (01-03) only build empty table structure --
no rows exist yet. This script reads patient_segmentation_dataset.csv
and inserts every row into the patient_data database, translating the
CSV's plain-text columns (State, Insurance_Type, Primary_Condition)
into the small integer IDs the normalized lookup tables expect.

WHAT THIS SCRIPT DOES, STEP BY STEP:
  1. Connects to MySQL.
  2. Inserts the fixed set of lookup values (the 10 states, 4 insurance
     types, 9 conditions) into their lookup tables -- these values are
     known ahead of time from profiling the CSV, so they're hardcoded
     here rather than being derived from the CSV at load time.
  3. Reads the CSV with pandas.
  4. For each row, looks up the matching lookup-table ID for State,
     Insurance_Type, and Primary_Condition.
  5. Converts the literal text 'Unknown' in the City column to a real
     NULL -- the database should store "we don't know the city" as an
     actual NULL, not as a string that means the same thing.
  6. Inserts all 2000 rows in a single batched executemany() call,
     which is far faster than running 2000 separate INSERT statements.

REQUIREMENTS:
  pip3 install pandas mysql-connector-python

USAGE:
  python3 load_patients.py
"""

import sys
import pandas as pd
import mysql.connector

# ---------------------------------------------------------------------
# CONFIG -- adjust these if your setup differs
# ---------------------------------------------------------------------
CSV_PATH = "patient_segmentation_dataset.csv"
DB_CONFIG = {
    "host": "localhost",
    "user": "root",
    "password": "",   # fill in your MySQL root password here
    "database": "patient_data",
}

# These are the fixed lookup values, derived from profiling the CSV.
# If your client gets a NEW csv with different states/conditions/
# insurance types in the future, add the new values here before
# re-running this script.
STATES = ["CA", "FL", "GA", "IL", "MI", "NC", "NY", "OH", "PA", "TX"]
INSURANCE_TYPES = ["Medicaid", "Medicare", "Private", "Self-Pay"]
CONDITIONS = [
    "Arthritis", "Depression", "Asthma", "Hypertension", "Anxiety",
    "Heart Disease", "Obesity", "COPD", "Diabetes",
]


def connect():
    try:
        return mysql.connector.connect(**DB_CONFIG)
    except mysql.connector.Error as err:
        print(f"Could not connect to MySQL: {err}")
        print("Check that MySQL is running (brew services start mysql)")
        print("and that DB_CONFIG above has the correct password.")
        sys.exit(1)


def seed_lookup_tables(cursor):
    """Insert the fixed lookup values if they aren't already there.

    INSERT IGNORE skips a row instead of erroring if it already exists
    (because of the UNIQUE constraint on each lookup table's name
    column) -- this makes the script safe to run more than once
    without creating duplicate lookup rows.
    """
    cursor.executemany(
        "INSERT IGNORE INTO states (state_code) VALUES (%s)",
        [(s,) for s in STATES],
    )
    cursor.executemany(
        "INSERT IGNORE INTO insurance_types (type_name) VALUES (%s)",
        [(i,) for i in INSURANCE_TYPES],
    )
    cursor.executemany(
        "INSERT IGNORE INTO conditions (condition_name) VALUES (%s)",
        [(c,) for c in CONDITIONS],
    )


def build_lookup_maps(cursor):
    """Read back the lookup tables to get name -> id mappings.

    We don't hardcode the IDs themselves (only the names above)
    because AUTO_INCREMENT values depend on insert order and could
    differ between machines -- always look the ID up by name instead
    of assuming, say, 'CA' is always state_id 1.
    """
    cursor.execute("SELECT state_id, state_code FROM states")
    state_map = {code: sid for sid, code in cursor.fetchall()}

    cursor.execute("SELECT insurance_type_id, type_name FROM insurance_types")
    insurance_map = {name: iid for iid, name in cursor.fetchall()}

    cursor.execute("SELECT condition_id, condition_name FROM conditions")
    condition_map = {name: cid for cid, name in cursor.fetchall()}

    return state_map, insurance_map, condition_map


def load_patients(cursor, df, state_map, insurance_map, condition_map):
    rows = []
    skipped = []

    for _, r in df.iterrows():
        # 'Unknown' in the CSV's City column means "we don't actually
        # know this" -- store it as a real NULL, not as the literal
        # string 'Unknown'.
        city = None if r["City"] == "Unknown" else r["City"]

        # Primary_Condition is blank for ~25% of patients (no primary
        # condition on record) -- pandas reads a blank CSV cell as
        # NaN, which pd.notna() catches here.
        condition_id = (
            condition_map.get(r["Primary_Condition"])
            if pd.notna(r["Primary_Condition"])
            else None
        )

        state_id = state_map.get(r["State"])
        insurance_type_id = insurance_map.get(r["Insurance_Type"])

        if state_id is None or insurance_type_id is None:
            # Defensive check: if a future CSV has a state or
            # insurance type we don't have in our lookup tables, skip
            # that row and report it rather than silently inserting a
            # wrong/NULL value into a NOT NULL foreign key.
            skipped.append(r["PatientID"])
            continue

        rows.append((
            r["PatientID"], int(r["Age"]), r["Gender"], state_id, city,
            int(r["Height_cm"]), int(r["Weight_kg"]), float(r["BMI"]),
            insurance_type_id, condition_id, int(r["Num_Chronic_Conditions"]),
            int(r["Annual_Visits"]), float(r["Avg_Billing_Amount"]),
            r["Last_Visit_Date"], int(r["Days_Since_Last_Visit"]),
            int(r["Preventive_Care_Flag"]),
        ))

    insert_sql = """
        INSERT IGNORE INTO patients
            (patient_id, age, gender, state_id, city, height_cm, weight_kg,
             bmi, insurance_type_id, condition_id, num_chronic_conditions,
             annual_visits, avg_billing_amount, last_visit_date,
             days_since_last_visit, preventive_care_flag)
        VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)
    """
    # INSERT IGNORE (rather than plain INSERT) makes this script safe
    # to run more than once: if a patient_id already exists, MySQL
    # skips that row instead of stopping the whole batch with a
    # "Duplicate entry" error. cursor.rowcount after an executemany
    # with INSERT IGNORE reports how many rows were ACTUALLY inserted,
    # which is how we detect skips below.
    cursor.executemany(insert_sql, rows)
    actually_inserted = cursor.rowcount
    duplicates = len(rows) - actually_inserted

    return actually_inserted, duplicates, skipped


def main():
    print(f"Reading {CSV_PATH} ...")
    df = pd.read_csv(CSV_PATH)
    print(f"  {len(df)} rows found in CSV")

    conn = connect()
    cursor = conn.cursor()

    print("Seeding lookup tables (states, insurance_types, conditions) ...")
    seed_lookup_tables(cursor)
    conn.commit()

    state_map, insurance_map, condition_map = build_lookup_maps(cursor)

    print("Loading patients ...")
    inserted, duplicates, skipped = load_patients(
        cursor, df, state_map, insurance_map, condition_map
    )
    conn.commit()

    print(f"  Inserted {inserted} new patient rows.")
    if duplicates:
        print(f"  Skipped {duplicates} rows that were already in the table (re-run is safe).")
    if skipped:
        print(f"  Skipped {len(skipped)} rows with unrecognized State/Insurance_Type: {skipped}")

    cursor.execute("SELECT COUNT(*) FROM patients")
    total = cursor.fetchone()[0]
    print(f"Total rows now in patients table: {total}")

    cursor.close()
    conn.close()


if __name__ == "__main__":
    main()
