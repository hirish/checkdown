from flask import Flask
from flask.ext.sqlalchemy import SQLAlchemy
from models import User, Debt, 
import json

app = Flask(__name__)
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///test.db'
db = SQLAlchemy(app)

@app.route('/')
def index():
    return 'Us teabagging Billsup.\n\nASCII-art coming soon.'

@app.route('/user/<user_id>/debt')
def get_user_debts(user_id):
    debts = Debt.query.filter_by(debter=user_id).order_by(Debt.created)
    return json.dumps(debts)


if __name__ == '__main__':
    app.run(debug=True)