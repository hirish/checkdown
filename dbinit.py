from models import *

db.create_all()

db.session.commit()

barn =  User('Barnaby Jackson', 'barnaby@henryirish.com', None)
henry = User('Henry Irish', 'facebook@henryirish.com', 1101575668)
fred =  User('Fred Kelly', 'fred@henryirish.com', 590344115)
matt =  User('Matt Bessey', 'matt@henryirish.com', None)
nick =  User('Nick Sampson', 'nick@henryirish.com', None)
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

db.session.add(Debt(henry, barn, magic, 1500, 'Sushi bill'))
db.session.add(Debt(henry, barn, magic, 2600, 'Bloodhound'))
db.session.add(Debt(barn, henry, magic, 260, 'Bloodhound'))
db.session.add(Debt(fred, henry, magic, 2600, 'Bloodhound'))
db.session.add(Debt(fred, barn, magic, 2600, 'Bloodhound'))
db.session.add(Debt(henry, barn, edgeb, 1700, 'Gas & Electric'))
db.session.add(Debt(barn, henry, edgeb, 3251, 'Comcast'))

db.session.commit()
