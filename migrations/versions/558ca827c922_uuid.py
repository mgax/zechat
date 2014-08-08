revision = '558ca827c922'
down_revision = None

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


def upgrade():
    op.create_table(
        'message',
        sa.Column('id', postgresql.UUID(), nullable=False),
        sa.Column('recipient', sa.String(), nullable=False),
        sa.Column('hash', sa.String(), nullable=False),
        sa.Column('payload', sa.String(), nullable=False),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index(
        op.f('ix_message_hash'),
        'message',
        ['hash'],
        unique=False,
    )
    op.create_index(
        op.f('ix_message_recipient'),
        'message',
        ['recipient'],
        unique=False,
    )

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


def downgrade():
    op.drop_index(op.f('ix_message_recipient'), table_name='message')
    op.drop_index(op.f('ix_message_hash'), table_name='message')
    op.drop_table('message')

    op.drop_index(op.f('ix_identity_fingerprint'), table_name='identity')
    op.drop_table('identity')
