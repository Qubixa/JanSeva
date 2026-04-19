"""Initial database setup

Revision ID: 001
Create Date: 2025-01-24
"""
from alembic import op
import sqlalchemy as sa

# Read SQL files
def upgrade():
    # Read and execute init SQL
    with open('scripts/001_init_database.sql', 'r') as f:
        init_sql = f.read()
    op.execute(init_sql)
    
    # Read and execute seed SQL
    with open('scripts/002_seed_data.sql', 'r') as f:
        seed_sql = f.read()
    op.execute(seed_sql)

def downgrade():
    # Drop all tables
    op.execute("DROP SCHEMA public CASCADE; CREATE SCHEMA public;")