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
      @setState 
        debts: @props.debts
        users: @props.users
        user: @props.users.get(@props.userId)
    {
      user: @props.users.get(@props.userId)
      debts: @props.debts
      users: @props.users
    }

  render: ->
    # if @state.userIsDebtor
    #   groupedDebts = @state.debts.debtorIs(@state.user).groupByLender()
    # else
    #   groupedDebts = @state.debts.lenderIs(@state.user).groupByDebtor()

    # groupedDebtsArray = ([key, groupedDebts[key]] for key of groupedDebts)

    # renderedUsers = groupedDebtsArray.map (group) =>
    renderedUsers = @state.users.map (otherUser) =>
      debts = @props.debts.debtorIs(@state.user).lenderIs(otherUser)
      loans = @props.debts.lenderIs(@state.user).debtorIs(otherUser)

      if debts.length > 0 or loans.length > 0
        MyUser
          user: @state.user
          username: otherUser.get('username')
          debts: debts
          loans: loans
      else
        return

    React.DOM.div {}, renderedUsers

MyUser = React.createClass
  render: ->
    {div, a, ul} = React.DOM
    total = @props.debts.totalAmount() - @props.loans.totalAmount()

    if total > 0
      startText = "You owe "
      renderedAmount = " a total of $" + total + ". "
    else if total < 0
      startText = "You are owed by "
      renderedAmount = " a total of $" + Math.abs(total) + ". "

    topText = [
      startText
      (a {style: {'font-weight': 'bold'}}, @props.username)
      renderedAmount
    ]

    if @props.debts.length > 0
      renderedDebts = @props.debts.map (debt) -> MyDebt debt: debt, isDebt: true

      debts = [
        "You owe "
        (a {style: {'font-weight': 'bold'}}, @props.username)
        " for:"
        (ul {className: "fa-ul debt-details"}, renderedDebts)
      ]
    else debts = []

    if @props.loans.length > 0
      renderedLoans = @props.loans.map (debt) -> MyDebt debt: debt, isDebt: false
      loans = [
        (a {style: {'font-weight': 'bold'}}, @props.username)
        " owes you for:"
        (ul {className: "fa-ul debt-details"}, renderedLoans)
      ]
    else loans = []

    (div {className: "person-debt"},
      topText,
      debts
      loans
      (MyButtons {total: total})
    )

MyDebt = React.createClass
  render: ->
    date = "08-22-2012"
    description = @props.debt.get('description')
    amount = @props.debt.get('amount')

    if @props.isDebt
      color = 'alert'
    else
      color = 'success'

    {li, i, span} = React.DOM
    (li {},
      (i {className: "fa-li fa fa-arrow-circle-right"}),
      (span {className: 'date'}, date + ': '),
      (span {className: 'description'}, description)
      (span {className: 'label right radius ' + color}, '$' + amount)
    )

MyButtons = React.createClass
  render: ->
    total = @props.total

    if total > 0
      buttons = MyPaymentButtons({total: total})
    else if total < 0
      buttons = MyChargeButtons({total: total})

    React.DOM.div {className: "text-center", style: {width: "100%"}}, buttons

MyPaymentButtons = React.createClass
  render: ->
    total = @props.total

    React.DOM.div({},
      React.DOM.button({className: "button tiny radius"}
        "Pay $" + total
      )," ",
      React.DOM.button({className: "button tiny radius success"}
        "Pay Other"
      )
    )

MyChargeButtons = React.createClass
  render: ->
    total = Math.abs @props.total

    React.DOM.div({},
      React.DOM.button({className: "button tiny radius"}
        "Charge $" + total
      )
    )

$ ->
  window.users = users = new Users()
  users.fetch()

  window.debts = debts = new Debts()
  debts.fetch users: users

  userId = 2

  React.renderComponent RecentList({debts: debts}), $('#debtviewholder')[0]
  React.renderComponent MyList({userId: userId, debts: debts, users: users}), $('#owe')[0]
