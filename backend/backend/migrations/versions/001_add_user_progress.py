"""Add user progress tracking

Revision ID: 001_add_user_progress
Revises: 
Create Date: 2024-01-01 00:00:00.000000

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision = '001_add_user_progress'
down_revision = None
branch_labels = None
depends_on = None


def upgrade():
    # Create user_progress table
    op.create_table('user_progress',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('user_id', sa.String(), nullable=True),
        sa.Column('total_sessions', sa.Integer(), nullable=True),
        sa.Column('total_xp', sa.Integer(), nullable=True),
        sa.Column('current_level', sa.Integer(), nullable=True),
        sa.Column('current_streak', sa.Integer(), nullable=True),
        sa.Column('longest_streak', sa.Integer(), nullable=True),
        sa.Column('last_session_date', sa.DateTime(), nullable=True),
        sa.Column('badges', sa.JSON(), nullable=True),
        sa.Column('stats', sa.JSON(), nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=True),
        sa.Column('updated_at', sa.DateTime(), nullable=True),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index('idx_user_progress_user_id', 'user_progress', ['user_id'], unique=False)


def downgrade():
    op.drop_index('idx_user_progress_user_id', table_name='user_progress')
    op.drop_table('user_progress')
