from models import *

db.create_all()

db.session.commit()

db.session.add(User('barndawg', 'barn@dawg.com', 1101575668))
db.session.add(User('henoogle', 'henry@irish.com', None))
db.session.add(User('test', None, None))
db.session.add(User('knife', None, None))
db.session.add(User('sausage', None, None))
db.session.add(User('lee.woodbridge', None, None))
db.session.add(User('matt.bessey', None, None))
db.session.add(User('henry', 'chocolate', None))

db.session.commit()
