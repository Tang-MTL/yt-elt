#!/bin/bash
set -euo pipefail

# init-multiple-databases.sh
# Creates roles and databases used by Airflow and the ELT process if they don't exist.
# Uses environment variables (from docker-compose env_file) to configure names and credentials.

: "${POSTGRES_USER:?POSTGRES_USER must be set}"
: "${POSTGRES_PASSWORD:?POSTGRES_PASSWORD must be set}"

METADATA_DB_NAME="${METADATA_DATABASE_NAME:-airflow_metadata_db}"
METADATA_DB_USER="${METADATA_DATABASE_USERNAME:-airflow_meta_user}"
METADATA_DB_PASS="${METADATA_DATABASE_PASSWORD:-airflow_pass}"

ELT_DB_NAME="${ELT_DATABASE_NAME:-elt_db}"
ELT_DB_USER="${ELT_DATABASE_USERNAME:-yt_api_user}"
ELT_DB_PASS="${ELT_DATABASE_PASSWORD:-elt_pass}"

CELERY_DB_NAME="${CELERY_BACKEND_NAME:-celery_results_db}"
CELERY_DB_USER="${CELERY_BACKEND_USERNAME:-celery_user}"
CELERY_DB_PASS="${CELERY_BACKEND_PASSWORD:-celery_pass}"

echo "Initializing Postgres: will ensure roles and databases exist"

# Create roles if they don't exist (safe idempotent DO block)
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-EOSQL
DO
\$do\$
BEGIN
   IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = '${METADATA_DB_USER}') THEN
      CREATE ROLE ${METADATA_DB_USER} WITH LOGIN PASSWORD '${METADATA_DB_PASS}';
   END IF;
   IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = '${ELT_DB_USER}') THEN
      CREATE ROLE ${ELT_DB_USER} WITH LOGIN PASSWORD '${ELT_DB_PASS}';
   END IF;
   IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = '${CELERY_DB_USER}') THEN
      CREATE ROLE ${CELERY_DB_USER} WITH LOGIN PASSWORD '${CELERY_DB_PASS}';
   END IF;
END
\$do\$;
EOSQL

# Create databases if they don't exist, set owner and grant privileges
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-EOSQL
SELECT 'CREATE DATABASE "' || datname || '"' FROM (SELECT '${METADATA_DB_NAME}'::text AS datname) d
  WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '${METADATA_DB_NAME}')\gexec
SELECT 'CREATE DATABASE "' || datname || '"' FROM (SELECT '${ELT_DB_NAME}'::text AS datname) d
  WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '${ELT_DB_NAME}')\gexec
SELECT 'CREATE DATABASE "' || datname || '"' FROM (SELECT '${CELERY_DB_NAME}'::text AS datname) d
  WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '${CELERY_DB_NAME}')\gexec

-- Assign owners (if DB exists)
ALTER DATABASE "${METADATA_DB_NAME}" OWNER TO ${METADATA_DB_USER};
ALTER DATABASE "${ELT_DB_NAME}" OWNER TO ${ELT_DB_USER};
ALTER DATABASE "${CELERY_DB_NAME}" OWNER TO ${CELERY_DB_USER};

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE "${METADATA_DB_NAME}" TO ${METADATA_DB_USER};
GRANT ALL PRIVILEGES ON DATABASE "${ELT_DB_NAME}" TO ${ELT_DB_USER};
GRANT ALL PRIVILEGES ON DATABASE "${CELERY_DB_NAME}" TO ${CELERY_DB_USER};
EOSQL

echo "Postgres initialization finished."
