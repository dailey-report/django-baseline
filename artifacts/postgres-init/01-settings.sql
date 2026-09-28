ALTER SYSTEM SET statement_timeout = '5s';
ALTER SYSTEM SET idle_in_transaction_session_timeout = '30s';
ALTER SYSTEM SET lock_timeout = '2s';
SELECT pg_reload_conf();
