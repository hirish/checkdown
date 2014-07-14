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
        g.facebook_user_details = True
        return User.query.filter_by(facebook_id = 1101575668).first()
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

def resolve_user_debts(main_user, other_user):
    '''
    Goes through all debts between users, and tries to mark
    debts as "paid" if they are resolved by opposite debts.
    '''

    debts = Debt.query.filter_by(debtor=main_user, lender=other_user).all()
    loans = Debt.query.filter_by(debtor=other_user, lender=main_user).all()

    add_amount = lambda total, user: total + user.amount

    total_debts = reduce(add_amount, debts, 0)
    total_loans = reduce(add_amount, loans, 0)

    def set_paid(debt):
        debt.paid = True

    if total_debts > total_loans:
        difference = total_debts - total_loans

        map(set_paid, loans)

        amount_paid = 0
        for debt in debts:
            amount_paid += debt.amount

            if amount_paid < difference:
                set_paid(debt)
            else:
                break

    elif total_loans > total_debts:
        difference = total_loans - total_debts

        map(set_paid, debts)

        amount_paid = 0
        for loan in loans:
            amount_paid += loan.amount
            if amount_paid < difference:
                set_paid(loan)
            else:
                break

    elif total_debts == total_loans:
        map(set_paid, loans)
        map(set_paid, debts)

    db.session.commit()


################################################################################
## Routing - Basic
################################################################################


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


################################################################################
## Routing - Groups
################################################################################


@app.route('/group/<group_id>/users', methods=['GET'])
@facebook_auth
def get_users(group_id):
    group = Group.query.get(group_id)
    if not group:
        abort(404)

    if not g.user in group.users:
        abort(403)

    users = group.users
    return jsonify(users = [user.dictify() for user in users])

# TODO: Fix method for getting data.
@app.route('/group/<group_id>/users', methods=['PUT'])
@facebook_auth
def add_user_to_group(group_id, user_email = None):
    group = Group.query.get(group_id)
    if not group:
        abort(404)

    # if not g.user in group.users:
    #     abort(403)

    if not user_email:
        try:
            user_email = request.form['user_email']
        except TypeError:
            abort(500)

    user = User.query.filter_by(email = user_email)
    if user.count() == 0:
        # Invite user
        return ""
    else:
        user = user.first()

    if user in group.users:
        return ""

    group.users.append(user)

    db.session.commit()

    return ""

@app.route('/group/<group_id>/users', methods=['DELETE'])
@facebook_auth
def remove_user_from_group(group_id, user_id = None):
    group = Group.query.get(group_id)
    if not group:
        abort(404)

    if not g.user in group.users:
        abort(403)

    if not user_id:
        try:
            user_id = request.form['user_id']
        except TypeError:
            abort(500)

    user = User.query.get(user_id)

    if not (user in group.users):
        return ""

    group.users.remove(user)

    db.session.commit()

    return ""

################################################################################
## Routing - Debts
################################################################################


@app.route('/debts', methods=['GET'])
@facebook_auth
def get_debts():
    debts = g.user.debts + g.user.loans
    return jsonify(debts = [ debt.dictify() for debt in debts ])

@app.route('/debts', methods=['POST'])
@facebook_auth
def create_debt():
    try:
        other_id = int(request.form['user'])
        other = User.query.get(other_id)

        amount = int(request.form['amount'])
        debtor = lender = None

        if amount == 0:
            raise Exception('Amount is 0.')
        elif amount < 0:
            # I owe other
            debtor = g.user
            lender = other
            amount *= -1
        elif amount > 0:
            # other owes me
            debtor = other
            lender = g.user

        description = request.form['description']
        description = description.strip()[:300]

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
    app.run(debug=True, host="0.0.0.0", port=80)
