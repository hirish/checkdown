from config import db
import hashlib
import json
import datetime

groups = db.Table('groups',
    db.Column('group_id', db.Integer, db.ForeignKey('group.id')),
    db.Column('user_id', db.Integer, db.ForeignKey('user.id'))
)

class User(db.Model):
    __tablename__ = 'user'

    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(80))
    email = db.Column(db.String(120), unique=True)
    facebook_id = db.Column(db.Integer, unique=True)
    groups = db.relationship(
        'Group',
        secondary=groups,
        backref=db.backref('users')
    )

    debts = db.relationship('Debt',
                            backref='debtor',
                            foreign_keys='Debt.debtor_id')

    loans = db.relationship('Debt',
                            backref='lender',
                            foreign_keys='Debt.lender_id')

    def __init__(self, username, email, facebook_id):
        self.username = username
        self.email = email
        self.facebook_id = facebook_id

    def dictify(self):
        return {
            'id' : self.id,
            'gravatar': hashlib.md5(self.email).hexdigest(),
            'username' : self.username,
            'email' : self.email,
            'groups' : [group.id for group in self.groups]
        }

    def json(self):
        return json.dumps(self.dictify())

    def __repr__(self):
        return '[User %r]' % self.username

class Group(db.Model):
    __table__name = 'group'
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(80), unique=True)

    def __init__(self, name):
        self.name = name

    def dictify(self):
        return {
            'id': self.id,
            'name': self.name
        }

    def __repr__(self):
        return '[Group %r]' % self.name

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

    def __init__(self, debtor, lender, amount, description, paid=False, created=None):
        if not created:
            created = datetime.datetime.utcnow()

        self.debtor = debtor
        self.lender = lender
        self.amount = amount
        self.description = description
        self.created = created
        self.paid = paid

    def dictify(self):
        return {
            'id' : self.id,
            'debtor_id' : self.debtor.id,
            'lender_id' : self.lender.id,
            'amount' : self.amount,
            'paid' : self.paid,
            'created' : str(self.created.date()),
            'description' : self.description,
        }

    def json(self):
        return json.dumps(self.dictify())

    def __repr__(self):
        if self.paid:
            return "[Debt: %s owed %s %i]" % (self.debtor,
                                              self.lender,
                                              self.amount)
        else:
            return "[Debt: %s OWES %s %i]" % (self.debtor,
                                              self.lender,
                                              self.amount)
