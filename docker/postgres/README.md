# Postgres init script

This directory contains `init-multiple-databases.sh`, an idempotent initialization script that runs inside the official `postgres` Docker image during container initialization.

What the script does

- Creates Postgres roles (users) if they do not exist, using values from the project's `.env` file:
  - `METADATA_DATABASE_USERNAME` (default: `airflow_meta_user`)
  - `ELT_DATABASE_USERNAME` (default: `yt_api_user`)
  - `CELERY_BACKEND_USERNAME` (default: `celery_user`)
- Creates databases if they do not exist, using names from `.env`:
  - `METADATA_DATABASE_NAME` (default: `airflow_metadata_db`)
  - `ELT_DATABASE_NAME` (default: `elt_db`)
  - `CELERY_BACKEND_NAME` (default: `celery_results_db`)
- Assigns database owners and grants privileges to the created roles.

Notes

- The script is idempotent and safe to keep in the repo; it will not re-create objects that already exist.
- The script relies on the `env_file` configured in `docker-compose.yaml` to supply values (the `.env` file at the repo root).
- Make sure `.env` is excluded from git (`.gitignore` already updated) to avoid committing secrets.

If you want the script to also pre-seed schemas or run SQL migrations, tell me what tables/data to add and I can extend it.
