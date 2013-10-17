from flask import abort, request, render_template
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
    return user.json()

@app.route('/user/<user_id>/debts')
def get_user_debts(user_id):
    debts = User.query.get(user_id).debts
    return json.dumps({'debts': [ debt.dictify() for debt in debts ]})

@app.route('/user/<user_id>/loans')
def get_user_loans(user_id):
    loans = User.query.get(user_id).loans
    return json.dumps({'loans': [ loan.dictify() for loan in loans ]})

@app.route('/create/user', methods=['POST'])
def create_user():
    try:
        username = request.form['username']
        username = username.strip()

        if len(username) == 0:
            raise Exception("Failed, username empty.")

        conflicts = User.query.filter_by(username=username).all()
        if len(conflicts) > 0:
            raise Exception("Failed, username already taken.")

        new_user = User(username, None)
        db.session.add(new_user)
        db.session.commit()

        return new_user.json()
    except Exception as e:
        app.logger.error(e)
        abort(500)

@app.route('/create/debt', methods=['POST'])
def create_debt():
    try:
        debtor_id = int(request.form['debtor_id'])
        lender_id = int(request.form['lender_id'])

        debtor = User.query.get(debtor_id)
        lender = User.query.get(lender_id)

        amount = int(request.form['amount'])
        if amount == 0:
          raise Exception('Amount is 0.')
        elif amount < 0:
          raise Exception('Amount cannot be less than 0.')

        description = request.form['description']
        description = description.strip()

        if len(description) == 0:
          raise Exception('Decription cannot be empty.')

        new_debt = Debt(debtor, lender, amount, description)
        db.session.add(new_debt)
        db.session.commit()

        return new_debt.json()
    except Exception as e:
        app.logger.error(e)
        abort(500)

@app.errorhandler(404)
@app.errorhandler(500)
def fail(error):
    colours = {404: "#036", 500: "#900"}
    colour = colours.get(error.code, "#000")
    return render_template('error.html', error=error.code, colour=colour), error.code

if __name__ == '__main__':
    app.run(debug=True)
