import logging
import os
from zechat.app import create_app

app = create_app(LISTEN_WEBSOCKET=True)
application = app.wsgi_app

if os.environ.get('FLASK_DEBUG') == 'on':
    from werkzeug.debug import DebuggedApplication
    app.debug = True
    application = DebuggedApplication(application, evalex=True)

logging.basicConfig(level=logging.DEBUG if app.debug else logging.INFO)
