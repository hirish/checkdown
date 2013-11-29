from flask import abort, request, render_template
from models import User, Debt
from config import app, db
import json

@app.route('/')
def index():
    #return 'Us teabagging Billsup.<br /><br/>ASCII-art coming soon.'
    return app.send_static_file('index.html')

@app.route('/users', methods=['GET', 'POST'])
def get_users():
    if request.method == "POST":
        try:
            username = request.json['username']
            email = request.json['email']
            username = username.strip()
            email = email.strip()

            if len(username) == 0 or len(email) == 0:
                raise Exception("Failed, username empty.")

            conflicts = User.query.filter_by(username=username).all()
            if len(conflicts) > 0:
                raise Exception("Failed, username already taken.")

            conflicts = User.query.filter_by(email=email).all()
            if len(conflicts) > 0:
                raise Exception("Failed, email already taken.")

            new_user = User(username, email)
            db.session.add(new_user)
            db.session.commit()

            return json.dumps({'id': new_user.id})
        except Exception as e:
            app.logger.error(e)
            abort(500)
    elif request.method == "GET":
        users = User.query.all()
        return json.dumps([ user.dictify() for user in users ] )

@app.route('/debts', methods=['GET', 'POST'])
def get_debts(group_id = None):
    if request.method == 'GET':
        debts = Debt.query.all()
        return json.dumps([ debt.dictify() for debt in debts ])
    elif request.method == 'POST':
        lender = User.query.get(request.json['lender']['id'])
        debtor = User.query.get(request.json['debtor']['id'])
        print lender, debtor

        if not(user_in_group(lender, group_id) and user_in_group(debtor, group_id)):
            print "Users not in group", lender, debtor, group_id
            abort(500)

        if lender.id == debtor.id:
            print "Users identical"
            abort(500)

        amount = request.json['amount']

        if not amount > 0:
            print "Amount not > 0"
            abort(500)

        description = request.json['description'].strip()[:300]

        new_debt = Debt(debtor = debtor, lender = lender, amount = amount, description = description)
        db.session.add(new_debt)
        db.session.commit()

        return json.dumps({'id': new_debt.id})


@app.route('/debts/<debt_id>', methods=['GET', 'PUT', 'DELETE'])
def update_debt(debt_id, group_id = None):
    debt = Debt.query.get(debt_id)
    if request.method == 'GET':
        return debt.json()

    elif request.method == 'PUT':
        lender = User.query.get(request.json['lender']['id'])
        debtor = User.query.get(request.json['debtor']['id'])

        if not(user_in_group(lender, group_id) and user_in_group(debtor, group_id)):
            print "Users not in group", lender, debtor, group_id
            abort(500)

        if lender.id == debtor.id:
            print "Users identical"
            abort(500)

        amount = request.json['amount']

        if not amount > 0:
            print "Amount not > 0"
            abort(500)

        description = request.json['description'].strip()[:300]

        debt.debtor = debtor
        debt.lender = lender
        debt.amount = amount
        debt.description = description
        debt.paid = request.json['paid']

        db.session.commit()

        return ""

    elif request.method == 'DELETE':
        print "Implement access control"
        db.session.delete(debt)
        db.session.commit()
        return ""

def user_in_group(user, group):
    return True

@app.route('/users/<user_id>', methods=['GET', 'PUT', 'DELETE'])
def get_user(user_id):
    user = User.query.get(user_id)
    if request.method == 'GET':
        return user.json()
    elif request.method == 'PUT':
        email = request.json['email']
        email.strip()
        user.email = email
        db.session.commit()
        return user.json()
    elif request.method == 'DELETE':
        print "Authentication for user deletion not yet implemented"
        abort(500)


@app.route('/user/<user_id>/debts')
def get_user_debts(user_id):
    debts = User.query.get(user_id).debts
    return json.dumps({'debts': [ debt.dictify() for debt in debts ]})

@app.route('/user/<user_id>/loans')
def get_user_loans(user_id):
    loans = User.query.get(user_id).loans
    return json.dumps({'loans': [ loan.dictify() for loan in loans ]})

# @app.route('/create/user', methods=['POST'])
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

# @app.errorhandler(404)
@app.errorhandler(500)
def fail(error):
    colours = {404: "#036", 500: "#900"}
    colour = colours.get(error.code, "#000")
    return render_template('error.html', error=error.code, colour=colour), error.code

if __name__ == '__main__':
    app.run(debug=True, host="0.0.0.0")
