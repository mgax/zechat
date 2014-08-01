#!/usr/bin/env python

from zechat.app import create_app, create_manager

app = create_app()
manager = create_manager(app)
manager.run()
