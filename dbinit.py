from models import *

db.create_all()

db.session.commit()

barn =  User('Barnaby Jackson', 'barney.jackson@live.com', None)
henry = User('Henry Irish', 'facebook@henryirish.com', 1101575668)
fred =  User('Fred Kelly', 'me@fredkelly.net', 590344115)
matt =  User('Matt Bessey', 'matt@henryirish.com', None)
nick =  User('Nick Sampson', 'nicksamps@gmail.com', None)
lee  =  User('Lee Woodbridge', 'lee@henryirish.com', None)
ben =   User('Ben Shaw', 'ben@henryirish.com', None)

[db.session.add(user) for user in [barn, henry, fred, matt, nick, lee, ben]]

svip =   Group('SVIP')
magic =  Group('Magic Four')
edgeb =  Group('Edgebagel Towers')
bernal = Group('Bernal Heights')

[db.session.add(group) for group in [svip, magic, edgeb]]

svip.users = [barn, henry, fred, matt, nick, lee, ben]
magic.users = [barn, henry, fred, nick]
edgeb.users = [barn, henry]
bernal.users = [lee, ben, matt]

db.session.add(Debt(henry, barn, magic, 1500, 'Sushi bill', False, datetime.datetime(2014,5,19)))
db.session.add(Debt(henry, barn, magic, 2600, 'Bloodhound', False, datetime.datetime(2014,5,30)))
db.session.add(Debt(barn, henry, magic, 0260, 'Bloodhound', False, datetime.datetime(2014,6,11)))
db.session.add(Debt(henry, barn, edgeb, 1700, 'Gas & Electric', True, datetime.datetime(2014,6,21)))
db.session.add(Debt(barn, henry, edgeb, 3251, 'Comcast', False, datetime.datetime(2014,6,23)))

db.session.add(Debt(fred, henry, magic, 2600, 'Bloodhound', False, datetime.datetime(2014,6,15)))
db.session.add(Debt(fred, barn, magic, 2600, 'Bloodhound', False, datetime.datetime(2014,6,19)))

db.session.commit()
