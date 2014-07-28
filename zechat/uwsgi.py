import os
from zechat.app import app as application

if os.environ.get('FLASK_DEBUG') == 'on':
    from werkzeug.debug import DebuggedApplication
    application.debug = True
    application = DebuggedApplication(application, evalex=True)
