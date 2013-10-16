from flask import Flask
from flask.ext.sqlalchemy import SQLAlchemy

app = Flask(__name__)
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///test.db'
db = SQLAlchemy(app)


class User(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(80), unique=True)
    email = db.Column(db.String(120), unique=True)

    def __init__(self, username, email):
        self.username = username
        self.email = email

    def __repr__(self):
        return '<User %r>' % self.username


class Debt(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    debtor = db.Column(db.Integer)
    lender = db.Column(db.Integer)

    # Stored as no. cents
    amount = db.Column(db.Integer)

    paid = db.Column(db.Boolean)

    def __init__(self, debtor, lender, amount):
        self.debtor = debtor
        self.lender = lender
        self.amount = amount
        self.paid = False

    def __repr__(self):
        if self.paid:
            return "<Debt: %i owed %i %i>" % (self.debtor,
                                              self.lender,
                                              self.amount)
        else:
            return "<Debt: %i owes %i %i>" % (self.debtor,
                                              self.lender,
                                              self.amount)
