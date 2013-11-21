User = Backbone.Model.extend
  defaults:
    username: 'None'
    email: 'None'
  toString: ->
    "[User: " + @get('username') + "]"

Debt = Backbone.Model.extend
  defaults:
    debtor: null
    lender: null
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
    return new Debts @filter (debt) ->
      debt.get('lender').id == user.id

  debtorIs: (user) ->
    return new Debts @filter (debt) ->
      debt.get('debtor').id == user.id

  groupByDebtor: ->
    grouped = @groupBy (debt) ->
      debt.get('debtor').get('username')
    for debtor of grouped
      grouped[debtor] = new Debts grouped[debtor]
    return grouped

  groupByLender: ->
    grouped = @groupBy (debt) ->
      debt.get('lender').get('username')
    for lender of grouped
      grouped[lender] = new Debts grouped[lender]
    return grouped

  totalAmount: ->
    @reduce ((x, y) -> x + y.get('amount')), 0


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

AllList = React.createClass
  getInitialState: ->
    @props.debts.on 'change add remove', (e) =>
      @setState {debts: @props.debts}
    {debts: @props.debts}

  render: ->
    renderedDebts = @state.debts.map (debt) -> AllDebt {debt: debt}
    React.DOM.div {id: "debtview"}, renderedDebts

AllDebt = React.createClass
  render: ->
    debtor = @props.debt.get('debtor').get('username')
    lender = @props.debt.get('lender').get('username')

    amount = @props.debt.get('amount')
    description = @props.debt.get('description')

    React.DOM.div({className: "debt"},
      React.DOM.div({className: "heading"},
        React.DOM.a({}, debtor),
        React.DOM.i({className: "fa fa-arrow-circle-right"}),
        React.DOM.a({}, lender),
        React.DOM.span({className: "amount"}, "$" + amount)
      )
      React.DOM.div({className: "description"}, description)
    )

debts = getDebts()

MyOwedList = React.createClass
  getInitialState: ->
    @props.debts.on 'change add remove', (e) =>
      @setState {debts: @props.debts}
    {user: @props.user, debts: @props.debts}

  render: ->
    groupedDebts = @state.debts.debtorIs(@state.user).groupByLender()
    groupedDebtsArray = ([key, groupedDebts[key]] for key of groupedDebts)

    renderedUsers = groupedDebtsArray.map (group) -> MyOwedUser {lender: group[0], debts: group[1]}
    React.DOM.div {}, renderedUsers

MyOwedUser = React.createClass
  render: ->
    username = @props.lender
    total = @props.debts.totalAmount()

    renderedDebts = @props.debts.map (debt) -> MyOwedDebt({debt: debt})

    React.DOM.div({className: "person-debt"},
      "You are owed by ",
      React.DOM.a({style: {'font-weight': 'bold'}}, username),
      " a total of $" + total,
      React.DOM.ul({className: "fa-ul debt-details"}, renderedDebts),
      MyButtons({total: total})
    )

MyOwedDebt = React.createClass
  render: ->
    date = "08-22-2012"
    description = @props.debt.get('description')
    amount = @props.debt.get('amount')

    React.DOM.li({},
      React.DOM.i({className: "fa-li fa fa-arrow-circle-right"}),
      React.DOM.span({className: 'date'}, date + ': '),
      React.DOM.span({className: 'description'}, description)
      React.DOM.span({className: 'badge amount positive'}, '$' + amount)
    )

MyButtons = React.createClass
  render: ->
    total = @props.total
    buttons = MyPaymentButtons({total})
    React.DOM.div {className: "btn-group", style: {width: "100%"}}, buttons

MyPaymentButtons = React.createClass
  render: ->
    total = @props.total

    React.DOM.div({style: {margin: "10px 30%"}},
      React.DOM.button({className: "btn btn-success btn-xs"}
        React.DOM.i({className: "fa fa-usd"}),
        "Pay $ " + total
      )," ",
      React.DOM.button({className: "btn btn-primary btn-xs"}
        React.DOM.i({className: "fa fa-usd"}),
        "Pay Other"
      )
    )

MyOwedView = Backbone.View.extend
  initialize: (args) ->
    @user = args.user
    @render()

  render: ->
    groupedDebts = @collection.debtorIs(@user).groupByLender()
    template = ''
    for lenderDebts of groupedDebts
      template += _.template $('#myowed').html(), {}
    @.$el.html template


$ ->
  window.debts = debts
  window.users = users
  window.user = user = users.models[1]

  # window.t = new MyOwedView el: $('#owe'), collection: debts, user: user

  React.renderComponent MyOwedList({user: user, debts: debts}), $('#owe')[0]
  React.renderComponent AllList({debts: debts}), $('#debtviewholder')[0]

  window.owe = owe = debts.debtorIs(user)
  window.owed = owed = debts.lenderIs(user)

