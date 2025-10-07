# migrations/env.py
from logging.config import fileConfig
from alembic import context
from sqlalchemy import engine_from_config, pool
import os, sys
from dotenv import load_dotenv

load_dotenv()

# ---- Alembic config & logging ----
config = context.config  # define this *before* using it
if config.config_file_name is not None:
    fileConfig(config.config_file_name)

# ---- PYTHONPATH so imports work when running from migrations/ ----
BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
if BASE_DIR not in sys.path:
    sys.path.insert(0, BASE_DIR)

# ---- Prefer env DATABASE_URL; fallback to alembic.ini ----
db_url = os.getenv("DATABASE_URL")
if db_url:
    config.set_main_option("sqlalchemy.url", db_url)

# ---- Your metadata (adjust import path if needed) ----
from app.core.db import Base  # make sure this path is correct
target_metadata = Base.metadata

def get_url():
    # return the effective URL Alembic will use
    return os.getenv("DATABASE_URL") or config.get_main_option("sqlalchemy.url")

def run_migrations_offline():
    url = get_url()
    if not url:
        raise RuntimeError("No sqlalchemy.url configured. Set DATABASE_URL or put it in alembic.ini.")
    context.configure(
        url=url,
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
        compare_type=True,
    )
    with context.begin_transaction():
        context.run_migrations()

def run_migrations_online():
    url = get_url()
    if not url:
        raise RuntimeError("No sqlalchemy.url configured. Set DATABASE_URL or put it in alembic.ini.")
    connectable = engine_from_config(
        config.get_section(config.config_ini_section) or {},
        prefix="sqlalchemy.",
        url=url,
        poolclass=pool.NullPool,
        future=True,
    )
    with connectable.connect() as connection:
        context.configure(connection=connection, target_metadata=target_metadata, compare_type=True)
        with context.begin_transaction():
            context.run_migrations()

if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
