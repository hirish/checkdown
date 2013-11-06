User = Backbone.Model.extend
  defaults:
    username: 'None'
    email: 'None'
  toString: ->
    "[User: " + @get('username') + "]"

Debt = Backbone.Model.extend
  defaults:
    debtor: null
    lendor: null
    description: 'None'
    created: null
    paid: false

  toString: ->
    if @get('paid')
      "[Debt: " + @get('debtor') + " owed " + @get('lender') + " " + @get('amount') + "]"
    else
      "[Debt: " + @get('debtor') + " owes " + @get('lender') + " " + @get('amount') + "]"

Users = Backbone.Collection.extend
  model: Users

Debts = Backbone.Collection.extend
  model: Debt

  lenderIs: (user) ->
    return @filter (debt) ->
      debt.get('lender').id == user.id

  debtorIs: (user) ->
    return @filter (debt) ->
      debt.get('debtor').id == user.id


getUsers = ->
  response = $.ajax '/users', async: false
  users = (jQuery.parseJSON response.responseText).users
  new Users (createUserFromJSON userJSON for userJSON in users)

createUserFromJSON = (json) ->
  return new User id:json.id, username:json.username, email: json.email

users = getUsers()

getDebts = ->
  response = $.ajax '/debts', async: false
  debts = (jQuery.parseJSON response.responseText).debts
  new Debts (createDebtFromJSON debtJSON for debtJSON in debts)

createDebtFromJSON = (json) ->
  debtor = users.get json.debtor.id
  lender = users.get json.lender.id

  return new Debt
    id: json.id
    debtor: debtor
    lender: lender
    description: json.description
    created: json.created
    paid: json.paid
    amount: json.amount

$ ->
  window.d = getDebts()
  window.u = getUsers()
