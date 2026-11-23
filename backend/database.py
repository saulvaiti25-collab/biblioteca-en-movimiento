"""Small database adapter for local SQLite and cloud PostgreSQL."""

from __future__ import annotations

import os
import sqlite3
from contextlib import contextmanager
from pathlib import Path
from typing import Any, Iterator


class Database:
    def __init__(self) -> None:
        url = os.getenv("DATABASE_URL", "").strip()
        self.is_postgres = url.startswith(("postgres://", "postgresql://"))
        self.url = url or f"sqlite:///{Path(__file__).with_name('biblioteca.db')}"

    @contextmanager
    def connection(self) -> Iterator[Any]:
        if self.is_postgres:
            import psycopg
            from psycopg.rows import dict_row

            with psycopg.connect(self.url, row_factory=dict_row, autocommit=True) as conn:
                yield conn
            return

        db_path = self.url.replace("sqlite:///", "", 1)
        conn = sqlite3.connect(db_path)
        conn.row_factory = sqlite3.Row
        try:
            yield conn
            conn.commit()
        finally:
            conn.close()

    def _query(self, query: str) -> str:
        return query.replace("?", "%s") if self.is_postgres else query

    @staticmethod
    def _dict(row: Any) -> dict[str, Any] | None:
        if row is None:
            return None
        return dict(row)

    def execute(self, query: str, params: tuple[Any, ...] = ()) -> None:
        with self.connection() as conn:
            cur = conn.cursor()
            try:
                cur.execute(self._query(query), params)
            finally:
                cur.close()

    def fetch_one(self, query: str, params: tuple[Any, ...] = ()) -> dict[str, Any] | None:
        with self.connection() as conn:
            cur = conn.cursor()
            try:
                cur.execute(self._query(query), params)
                return self._dict(cur.fetchone())
            finally:
                cur.close()

    def fetch_all(self, query: str, params: tuple[Any, ...] = ()) -> list[dict[str, Any]]:
        with self.connection() as conn:
            cur = conn.cursor()
            try:
                cur.execute(self._query(query), params)
                return [dict(row) for row in cur.fetchall()]
            finally:
                cur.close()

    def insert_id(self, query: str, params: tuple[Any, ...] = ()) -> int:
        with self.connection() as conn:
            cur = conn.cursor()
            try:
                if self.is_postgres:
                    cur.execute(self._query(query) + " RETURNING id", params)
                    return int(cur.fetchone()["id"])
                cur.execute(query, params)
                return int(cur.lastrowid)
            finally:
                cur.close()

    def initialize(self) -> None:
        if self.is_postgres:
            statements = POSTGRES_SCHEMA
        else:
            statements = SQLITE_SCHEMA
        with self.connection() as conn:
            cur = conn.cursor()
            try:
                for statement in statements:
                    cur.execute(statement)
            finally:
                cur.close()


SQLITE_SCHEMA = [
    """CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        username TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        role TEXT NOT NULL CHECK(role IN ('admin','bibliotecario','estudiante')),
        active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL
    )""",
    """CREATE TABLE IF NOT EXISTS books (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        author TEXT NOT NULL,
        category TEXT NOT NULL,
        isbn TEXT,
        cover_url TEXT,
        description TEXT,
        active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL
    )""",
    """CREATE TABLE IF NOT EXISTS loans (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL REFERENCES users(id),
        book_id INTEGER NOT NULL REFERENCES books(id),
        borrowed_at TEXT NOT NULL,
        due_at TEXT NOT NULL,
        returned_at TEXT,
        notes TEXT
    )""",
    "CREATE INDEX IF NOT EXISTS idx_loans_active_book ON loans(book_id, returned_at)",
]

POSTGRES_SCHEMA = [
    """CREATE TABLE IF NOT EXISTS users (
        id BIGSERIAL PRIMARY KEY,
        name TEXT NOT NULL,
        username TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        role TEXT NOT NULL CHECK(role IN ('admin','bibliotecario','estudiante')),
        active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL
    )""",
    """CREATE TABLE IF NOT EXISTS books (
        id BIGSERIAL PRIMARY KEY,
        title TEXT NOT NULL,
        author TEXT NOT NULL,
        category TEXT NOT NULL,
        isbn TEXT,
        cover_url TEXT,
        description TEXT,
        active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL
    )""",
    """CREATE TABLE IF NOT EXISTS loans (
        id BIGSERIAL PRIMARY KEY,
        user_id BIGINT NOT NULL REFERENCES users(id),
        book_id BIGINT NOT NULL REFERENCES books(id),
        borrowed_at TEXT NOT NULL,
        due_at TEXT NOT NULL,
        returned_at TEXT,
        notes TEXT
    )""",
    "CREATE INDEX IF NOT EXISTS idx_loans_active_book ON loans(book_id, returned_at)",
]
