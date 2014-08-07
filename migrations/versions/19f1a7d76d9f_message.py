revision = '19f1a7d76d9f'
down_revision = '229e58fc9f4b'

from alembic import op
import sqlalchemy as sa


def upgrade():
    op.create_table('message',
        sa.Column('id', sa.Integer(), nullable=False),
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


def downgrade():
    op.drop_index(op.f('ix_message_recipient'), table_name='message')
    op.drop_index(op.f('ix_message_hash'), table_name='message')
    op.drop_table('message')
