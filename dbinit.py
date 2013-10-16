from model import *

db.create_all()

b = User('barndawg', 'barn@dawg.com')
h = User('henoogle', 'henry@irish.com')

db.session.add(b)
db.session.add(h)

d = Debt(b, h, 100)

db.session.add(d)

db.session.commit()

print User.query.all()
print Debt.query.all()
