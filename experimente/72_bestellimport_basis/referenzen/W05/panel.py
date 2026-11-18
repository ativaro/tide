import sqlite3
from contextlib import closing


def main(db: str, ids: list[str]) -> int:
    with closing(sqlite3.connect(db)) as connection, connection:
        connection.execute("BEGIN")
        connection.execute("CREATE TABLE IF NOT EXISTS receipt(id TEXT PRIMARY KEY)")
        connection.executemany("INSERT OR IGNORE INTO receipt(id) VALUES(?)", ((item,) for item in ids))
        return connection.execute("SELECT COUNT(*) FROM receipt").fetchone()[0]
