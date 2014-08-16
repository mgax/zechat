revision = '52ceb70dfec2'
down_revision = '17cabe4a8491'

from alembic import op
import sqlalchemy as sa


def upgrade():
    op.execute("DELETE FROM message")
    op.add_column(
        'message',
        sa.Column('sender', sa.String(), nullable=False),
    )
    op.create_index(
        op.f('ix_message_sender'),
        'message',
        ['sender'],
        unique=False,
    )


def downgrade():
    op.drop_index(op.f('ix_message_sender'), table_name='message')
    op.drop_column('message', 'sender')
