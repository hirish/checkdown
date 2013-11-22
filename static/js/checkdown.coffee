User = Backbone.Model.extend
  initialize: (o) ->
    @set('username', o.username)
    @set('email', o.email)
    @set('id', o.id)

  defaults:
    username: 'None'
    email: 'None'

  toString: ->
    "[User: " + @get('username') + "]"

Debt = Backbone.Model.extend
  initialize: (o, options) ->
    users = options.users
    lender = users.get o.lender.id
    debtor = users.get o.debtor.id

    @set('id', o.id)
    @set('lender', lender)
    @set('debtor', debtor)
    @set('amount', o.amount)
    @set('created', o.created)

    # Optional
    @set('paid', o.paid) if o.paid?
    @set('description', o.description) if o.description?

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
  url: "users"
  model: User

Debts = Backbone.Collection.extend
  url: "debts"
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


##################################################
### Views: Recent Debts
##################################################

RecentList = React.createClass
  getInitialState: ->
    @props.debts.on 'change add remove', (e) =>
      @setState {debts: @props.debts}
    {debts: @props.debts}

  render: ->
    renderedDebts = @state.debts.map (debt) -> RecentDebt {debt: debt}
    React.DOM.div {id: "debtview"}, renderedDebts

RecentDebt = React.createClass
  render: ->
    debtor = @props.debt.get('debtor').get('username')
    lender = @props.debt.get('lender').get('username')

    amount = @props.debt.get('amount')
    description = @props.debt.get('description')

    {div, a, i, span} = React.DOM
    (div {className: "debt"},
      (div {className: "heading"},
        (a {}, debtor),
        (i {className: "fa fa-arrow-circle-right"}),
        (a {}, lender),
        (span {className: "amount"}, "$" + amount)
      )
      (div {className: "description"}, description)
    )

##################################################
### Views: My coalesced debts and loans
##################################################

MyList = React.createClass
  getInitialState: ->
    @props.debts.on 'change add remove', (e) =>
      @setState {debts: @props.debts, user: @props.debts.get(@props.userId)}
    {user: @props.debts.get(@props.userId), debts: @props.debts, userIsDebtor: @props.userIsDebtor}

  render: ->
    if @state.userIsDebtor
      groupedDebts = @state.debts.debtorIs(@state.user).groupByLender()
    else
      groupedDebts = @state.debts.lenderIs(@state.user).groupByDebtor()

    groupedDebtsArray = ([key, groupedDebts[key]] for key of groupedDebts)

    renderedUsers = groupedDebtsArray.map (group) =>
      MyUser
        otherUser: group[0]
        debts: group[1]
        userIsDebtor: @state.userIsDebtor

    React.DOM.div {}, renderedUsers

MyUser = React.createClass
  render: ->
    username = @props.otherUser
    total = @props.debts.totalAmount()

    if @props.userIsDebtor
      text = "You owe "
    else
      text = "You are owed by "

    renderedDebts = @props.debts.map (debt) =>
      MyDebt
        debt: debt
        userIsDebtor: @props.userIsDebtor

    {div, a, ul} = React.DOM
    (div {className: "person-debt"},
      text, (a {style: {'font-weight': 'bold'}}, username), " a total of $" + total,
      (ul {className: "fa-ul debt-details"}, renderedDebts),
      (MyButtons {total: total, userIsDebtor: @props.userIsDebtor})
    )

MyDebt = React.createClass
  render: ->
    date = "08-22-2012"
    description = @props.debt.get('description')
    amount = @props.debt.get('amount')

    {li, i, span} = React.DOM
    (li {},
      (i {className: "fa-li fa fa-arrow-circle-right"}),
      (span {className: 'date'}, date + ': '),
      (span {className: 'description'}, description)
      (span {className: 'badge amount positive'}, '$' + amount)
    )

MyButtons = React.createClass
  render: ->
    total = @props.total

    if @props.userIsDebtor
      buttons = MyPaymentButtons({total: total})
    else
      buttons = MyChargeButtons({total: total})

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

MyChargeButtons = React.createClass
  render: ->
    total = @props.total

    React.DOM.div({style: {margin: "10px 30%"}},
      React.DOM.button({className: "btn btn-success btn-xs"}
        React.DOM.i({className: "fa fa-usd"}),
        "Charge $ " + total
      )
    )

$ ->
  window.users = users = new Users()
  users.fetch()

  window.debts = debts = new Debts()
  debts.fetch users: users

  userId = 2

  React.renderComponent RecentList({debts: debts}), $('#debtviewholder')[0]
  React.renderComponent MyList({userId: userId, debts: debts, userIsDebtor: true}), $('#owe')[0]
  React.renderComponent MyList({userId: userId, debts: debts, userIsDebtor: false}), $('#owed')[0]
