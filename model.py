from flask import Flask
from flask.ext.sqlalchemy import SQLAlchemy

app = Flask(__name__)
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///test.db'
db = SQLAlchemy(app)


class User(db.Model):
    __tablename__ = 'user'

    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(80), unique=True)
    email = db.Column(db.String(120), unique=True)

    debts = db.relationship('Debt',
                            backref='debtor',
                            foreign_keys='Debt.debtor_id')

    loans = db.relationship('Debt',
                            backref='lender',
                            foreign_keys='Debt.lender_id')

    def __init__(self, username, email):
        self.username = username
        self.email = email

    def __repr__(self):
        return '<User %r>' % self.username


class Debt(db.Model):
    __tablename__ = 'debt'

    id = db.Column(db.Integer, primary_key=True)

    debtor_id = db.Column(db.Integer, db.ForeignKey('user.id'))
    lender_id = db.Column(db.Integer, db.ForeignKey('user.id'))

    # Stored as no. cents
    amount = db.Column(db.Integer)

    paid = db.Column(db.Boolean)

    created = db.Column(db.DateTime)

    description = db.Column(db.String(300))

    def __init__(self, debtor, lender, amount):
        self.debtor = debtor
        self.lender = lender
        self.amount = amount
        self.paid = False

    def __repr__(self):
        if self.paid:
            return "<Debt: %s owed %s %i>" % (self.debtor,
                                              self.lender,
                                              self.amount)
        else:
            return "<Debt: %s owes %s %i>" % (self.debtor,
                                              self.lender,
                                              self.amount)
