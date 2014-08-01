revision = '229e58fc9f4b'
down_revision = None

from alembic import op
import sqlalchemy as sa


def upgrade():
    op.create_table(
        'identity',
        sa.Column('id', sa.Integer(), nullable=False),
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


def downgrade():
    op.drop_index(op.f('ix_identity_fingerprint'), table_name='identity')
    op.drop_table('identity')
