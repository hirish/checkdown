from models import User, Debt 
from config import app, db
import json

@app.route('/')
def index():
    #return 'Us teabagging Billsup.<br /><br/>ASCII-art coming soon.'
    return app.send_static_file('index.html')

@app.route('/user/<user_id>')
def get_user(user_id):
  user = User.query.get(user_id)
  return user.__repr__()

@app.route('/user/<user_id>/debt')
def get_user_debts(user_id):
    debtor = User.query.get(user_id)
    debts = Debt.query.filter_by(debtor=debtor).order_by(Debt.created)
    return debts.stringify


if __name__ == '__main__':
    app.run(debug=True)
