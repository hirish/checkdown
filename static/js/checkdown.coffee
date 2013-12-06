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

  between: (user1, user2) ->
    return new Debts @filter (debt) ->
      debt.get('debtor').id == user1.id and debt.get('lender').id == user2.id or debt.get('debtor').id == user2.id and debt.get('lender').id == user1.id

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
    @props.users.on 'change add remove', (e) =>
      @setState 
        debts: @props.debts
        users: @props.users
        user: @props.users.get(@props.userId)
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
      debts = @props.debts.between(@state.user, otherUser)
      if debts.length > 0
        MyUser
          user: @state.user
          otherUser: otherUser
          debts: debts
      else
        return

    React.DOM.div {}, renderedUsers

MyUser = React.createClass
  render: ->
    {div, a, ul, h2} = React.DOM
    total = @props.debts.lenderIs(@props.user).totalAmount() - @props.debts.debtorIs(@props.user).totalAmount()

    xs = [0, 10, 15, 20, 25, 30, 35, 40, 45, 50, 60]
    ys = [0, 40, -150, -130, -50, -20, 40, 0, 80, 90, 100]
    values = []
    for i in [0..10]
      values.push {x:xs[i], y:ys[i]}

    (div {className: "person-debt"},
      (h2 {}, @props.otherUser.get('username'))
      (div {className: "graph"},
        (LineGraph {normaliseYAxis: true, autoResize: true, valueLists: [values]})
      )
      (MyDebtTable {debts: @props.debts, user: @props.user})
      (MyButtons {total: total})
    )

MyDebtTable = React.createClass
  render: ->
    {table, thead, tr, th, td, tbody} = React.DOM

    cumulative = 0
    debtLines = @props.debts.map (debt) =>
      isDebt = (debt.get('debtor').id == @props.user.id)

      if isDebt
        cumulative -= debt.get('amount')
      else
        cumulative += debt.get('amount')

      MyDebt debt: debt, isDebt: isDebt, cumulative: cumulative

    (table {className: "medium-12 columns"},
      (thead {},
        (tr {},
          (th {width: 100}, "Date")
          (th {}, "Description")
          (th {width: 80}, "Amount")
          (th {className: "show-for-medium-up", width: 80}, "Culmulative")
        )
      )
      (tbody {},
        debtLines
      )
    )

MyDebt = React.createClass
  render: ->
    date = "08-22-2012"
    description = @props.debt.get('description')
    amount = @props.debt.get('amount')
    cumulative = @props.cumulative

    type = if @props.isDebt then 'debt' else 'loan'

    {tr, td} = React.DOM
    (tr {className: type},
      (td {}, date),
      (td {}, description)
      (td {}, '$' + amount)
      (td {className: "show-for-medium-up"}, '$' + cumulative)
    )

MyButtons = React.createClass
  render: ->
    total = @props.total

    if total < 0
      buttons = MyPaymentButtons({total: total})
    else
      buttons = MyChargeButtons({total: total})

    React.DOM.div {className: "text-center", style: {width: "100%"}}, buttons

MyPaymentButtons = React.createClass
  render: ->
    total = Math.abs @props.total

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
  window.fbAsyncInit = ->
    FB.init
      appId      : '422041944562938'
      status     : true
      cookie     : true
      xfbml      : true

    FB.Event.subscribe 'auth.authResponseChange', (response) ->
      if response.status == 'connected'
        $('#login').addClass 'off'
        window.users = users = new Users()
        users.fetch()

        window.debts = debts = new Debts()
        debts.fetch users: users

        userId = 2

        window.recentlist = React.renderComponent RecentList({debts: debts}), $('#debtviewholder')[0]
        window.mylist = React.renderComponent MyList({userId: userId, debts: debts, users: users}), $('#owe')[0]
      else if response.status == 'not_authorized'
        FB.login()
      else
        FB.login()

  `(function(d){
   var js, id = 'facebook-jssdk', ref = d.getElementsByTagName('script')[0];
   if (d.getElementById(id)) {return;}
   js = d.createElement('script'); js.id = id; js.async = true;
   js.src = "//connect.facebook.net/en_US/all.js";
   ref.parentNode.insertBefore(js, ref);
  }(document));`

  testAPI = ->
    console.log 'Welcome!  Fetching your information.... '
    FB.api '/me', (response) ->
      console.log 'Good to see you, ' + response.name + '.'

# 
#   xs = [0, 10, 15, 20, 25, 30, 35, 40, 45, 50, 60]
#   ys = [0, 40, -150, -130, -50, -20, 40, 0, 80, 90, 100]
#   values = []
#   for i in [0..10]
#     values.push {x:xs[i], y:ys[i]}
#   window.v = values
# 
#   React.renderComponent LineGraph({normaliseYAxis: true, valueLists: [values], parent: $('#other')}), $('#other')[0]
