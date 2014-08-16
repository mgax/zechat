revision = '17cabe4a8491'
down_revision = '558ca827c922'

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

def upgrade():
    op.drop_index(op.f('ix_identity_fingerprint'), table_name='identity')
    op.drop_table('identity')


def downgrade():
    op.create_table(
        'identity',
        sa.Column('id', postgresql.UUID(), nullable=False),
        sa.Column('fingerprint', sa.String(), nullable=False),
        sa.Column('public_key', sa.String(), nullable=False),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index(
        op.f('ix_identity_fingerprint'),
        'identity',
        ['fingerprint'],
        unique=True,
    )
