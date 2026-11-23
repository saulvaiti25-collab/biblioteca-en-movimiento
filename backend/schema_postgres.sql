-- Esquema de referencia para Aiven PostgreSQL.
-- La API crea estas tablas automáticamente al iniciar.
CREATE TABLE users (
  id BIGSERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  username TEXT NOT NULL UNIQUE,
  password_hash TEXT NOT NULL,
  role TEXT NOT NULL CHECK (role IN ('admin','bibliotecario','estudiante')),
  active INTEGER NOT NULL DEFAULT 1,
  created_at TEXT NOT NULL
);

CREATE TABLE books (
  id BIGSERIAL PRIMARY KEY,
  title TEXT NOT NULL,
  author TEXT NOT NULL,
  category TEXT NOT NULL,
  isbn TEXT,
  cover_url TEXT,
  description TEXT,
  active INTEGER NOT NULL DEFAULT 1,
  created_at TEXT NOT NULL
);

CREATE TABLE loans (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT NOT NULL REFERENCES users(id),
  book_id BIGINT NOT NULL REFERENCES books(id),
  borrowed_at TEXT NOT NULL,
  due_at TEXT NOT NULL,
  returned_at TEXT,
  notes TEXT
);
