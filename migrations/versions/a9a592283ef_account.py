revision = 'a9a592283ef'
down_revision = '52ceb70dfec2'

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


def upgrade():
    op.create_table(
        'account',
        sa.Column('id', postgresql.UUID(), nullable=False),
        sa.Column('pubkey', sa.String(), nullable=False),
        sa.Column('state', sa.String(), nullable=False),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index(
        op.f('ix_account_pubkey'),
        'account',
        ['pubkey'],
        unique=True,
    )


def downgrade():
    op.drop_index(op.f('ix_account_pubkey'), table_name='account')
    op.drop_table('account')
