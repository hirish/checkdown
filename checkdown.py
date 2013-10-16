from models import User, Debt 
from config import app, db
import json

@app.route('/')
def index():
    #return 'Us teabagging Billsup.<br /><br/>ASCII-art coming soon.'
    return app.send_static_file('index.html')

@app.route('/users')
def get_users():
    users = User.query.all()
    return json.dumps({'users': [ user.dictify() for user in users ] })

@app.route('/debts')
def get_debts():
    debts = Debt.query.all()
    return json.dumps({'debts': [ debt.dictify() for debt in debts ] })

@app.route('/user/<user_id>')
def get_user(user_id):
  user = User.query.get(user_id)
  return user.__repr__()

@app.route('/user/<user_id>/debts')
def get_user_debts(user_id):
    debtor = User.query.get(user_id)
    debts = Debt.query.filter_by(debtor=debtor).order_by(Debt.created)
    return json.dumps({'debts': [ debt.dictify() for debt in debts.all() ]})

@app.route('/user/<user_id>/loans')
def get_user_loans(user_id):
    lender = User.query.get(user_id)
    loans = Debt.query.filter_by(lender=lender).order_by(Debt.created)
    return json.dumps({'loans': [ loan.dictify() for loan in loans.all() ]})

if __name__ == '__main__':
    app.run(debug=True)
