from flask import Flask
from flask.ext.sqlalchemy import SQLAlchemy

app = Flask(__name__, static_folder='static', static_url_path='')
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///test.db'
db = SQLAlchemy(app)
app.secret_key = 'HenryIsAwesome'

app_id = "422041944562938"
app_key = "0b08e0196edc9f7e2e301fbe14303b94"

