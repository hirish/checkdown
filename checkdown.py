"""
This is a docstring
"""

from flask import abort, request, render_template, jsonify, json, g, redirect
from models import User, Debt, Group
from config import app, db, app_id, app_key
import facebook
from functools import wraps

def get_logged_in_user():
    "Returns the logged in user or 'None' if no user is logged in"
    try:
        user_details = facebook.parse_signed_request(
            request.cookies['fbsr_' + app_id],
            app_key
        )
        facebook_id = user_details['user_id']
        g.facebook_user_details = user_details
        return User.query.filter_by(facebook_id = facebook_id).first()
    except (KeyError, TypeError):
        return None

def facebook_auth(function):
    "Check whether user is logged in, 503 Unauthorized if not"
    @wraps(function)
    def wrapper(*args, **kwds):
        "Closure checks whether user is logged in, otherwise fires function"
        user = get_logged_in_user()
        if not user:
            abort(403)
        g.user = user
        return function(*args, **kwds)
    return wrapper

@app.route('/')
def index():
    "Default homepage, served statically"
    if get_logged_in_user():
        # TODO: Prepopulate data and hide login screen.
        return render_template('index.html')
    else:
        return render_template('index.html')

@app.route('/user')
def get_user():
    "Returns currently logged in user, registering a new user if necessary"
    user = get_logged_in_user()
    if not 'facebook_user_details' in g:
        abort(403)
    if not user:
        fb_code = g.facebook_user_details['code']
        fb_access_token = facebook.get_access_token_from_code(
            fb_code,
            '',
            app_id,
            app_key
        )['access_token']

        graph = facebook.GraphAPI(fb_access_token)
        fb_details = graph.get_object('me')

        username = fb_details['name']
        email = fb_details['email']
        facebook_id = g.facebook_user_details['user_id']

        user = User(username, email, facebook_id)
        db.session.add(user)
        db.session.commit()

    return jsonify(user = user.dictify())

@app.route('/logout')
def logout():
    response = redirect('/')
    response.set_cookie('fbsr_' + app_id, '')
    return response

@app.route('/group/<group_id>')
@facebook_auth
def get_group_name(group_id):
    group = Group.query.get(group_id)
    if not group:
        abort(404)

    return jsonify(group = group.dictify())

@app.route('/group/<group_id>/users')
@facebook_auth
def get_users(group_id):
    group  = Group.query.get(group_id)
    if not group:
        abort(404)

    if not g.user in group.users:
        abort(403)

    users = group.users
    return jsonify(users = [user.dictify() for user in users])

@app.route('/group/<group_id>/debts', methods=['GET', 'POST'])
@facebook_auth
def get_debts(group_id):
    if request.method == 'GET':
        group  = Group.query.get(group_id)
        if not group:
            abort(404)

        if not g.user in group.users:
            abort(403)

        print group.debts

        debts = group.debts
        return jsonify(debts = [ debt.dictify() for debt in debts ])
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
@facebook_auth
def debt(debt_id, group_id = None):
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

# @app.route('/users/<user_id>', methods=['GET', 'PUT', 'DELETE'])
# @facebook_auth
# def get_user(user_id):
#     user = User.query.get(user_id)
#     if request.method == 'GET':
#         return user.json()
#     elif request.method == 'PUT':
#         email = request.json['email']
#         email.strip()
#         user.email = email
#         db.session.commit()
#         return user.json()
#     elif request.method == 'DELETE':
#         print "Authentication for user deletion not yet implemented"
#         abort(500)
#

@app.route('/user/<user_id>/debts')
@facebook_auth
def get_user_debts(user_id):
    debts = User.query.get(user_id).debts
    return json.dumps({'debts': [ debt.dictify() for debt in debts ]})

@app.route('/user/<user_id>/loans')
@facebook_auth
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
@facebook_auth
def create_debt():
    print request.form
    abort(500)
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
    print error
    colours = {404: "#036", 500: "#900"}
    colour = colours.get(error.code, "#000")
    return render_template('error.html', error=error.code, colour=colour), error.code

if __name__ == '__main__':
    app.run(debug=True, host="0.0.0.0")
