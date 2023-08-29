ALTER DATABASE rinha set synchronous_commit=OFF;

ALTER SYSTEM SET shared_buffers TO "512MB";
ALTER SYSTEM SET effective_cache_size TO "1GB";
ALTER SYSTEM SET effective_io_concurrency = 10;
ALTER SYSTEM SET max_connections = 1000;

-- ALTER SYSTEM SET log_min_messages TO "PANIC";
-- ALTER SYSTEM SET log_min_error_statement TO "PANIC";
ALTER SYSTEM SET log_lock_waits = ON;
ALTER SYSTEM SET fsync = OFF;

CREATE TABLE IF NOT EXISTS people
(
    id UUID PRIMARY KEY,
    nickname VARCHAR(32) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    birthdate CHAR(10) NOT NULL,
    stack TEXT NULL,
    search TEXT NOT NULL
);

CREATE EXTENSION IF NOT EXISTS "pg_trgm";
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_people_trigram ON people USING gist (search gist_trgm_ops(siglen = 64));

-- CREATE INDEX people_id_index ON people (id);
-- CREATE INDEX people_nickname_index ON people (nickname);
