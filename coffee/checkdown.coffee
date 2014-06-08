`/** @jsx React.DOM */`

User = Backbone.Model.extend
  toString: ->
    "[User: " + @get('username') + "]"

Debt = Backbone.Model.extend
  toString: ->
    if @get('paid')
      "[Debt: " + @get('debtor') + " owed " + @get('lender') + " " + @get('amount') + "]"
    else
      "[Debt: " + @get('debtor') + " owes " + @get('lender') + " " + @get('amount') + "]"

Group = Backbone.Model.extend
    initialize: (o) ->
        @set 'name', o.name
        @set 'id', o.id

    toString: ->
        "[Group: #{@get('name')}]"

Users = Backbone.Collection.extend
  url: "users"
  model: User

Debts = Backbone.Collection.extend
    url: "debts"
    model: Debt

    userInvolved: (user) ->
        return new Debts @filter (debt) ->
            debt.get('lender_id') is user.id or debt.get('debtor_id') is user.id

    lenderIs: (user) ->
        return new Debts @filter (debt) ->
          debt.get('lender_id') is user.id

    debtorIs: (user) ->
        return new Debts @filter (debt) ->
          debt.get('debtor_id') is user.id

    groupIs: (groupId) ->
        return new Debts @filter (debt) ->
          debt.get('group_id') is groupId

    between: (user1, user2) ->
        return new Debts @filter (debt) ->
          debt.get('debtor').id == user1.id and debt.get('lender').id == user2.id or debt.get('debtor').id == user2.id and debt.get('lender').id == user1.id

    groupByUsers: (user) ->
        grouped = @groupBy (debt) ->
            if debt.get('debtor_id') is user.get('id')
                debt.get('lender_id')
            else
                debt.get('debtor_id')
        for user of grouped
            grouped[user] = new Debts grouped[user]

        grouped

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

Groups = Backbone.Collection.extend
    model: Group


##################################################
### Views
##################################################

Application = React.createClass
    getInitialState: ->
        selectedGroup: null

    componentWillMount: ->
        @props.groups.on 'add remove', =>
            @forceUpdate()

        @props.debts.on 'add remove', =>
            @forceUpdate()

    selectGroup: (id) ->
        @setState selectedGroup: id

    createDebt: (debt) ->
        $.post '/debt', debt
          .done ->
              console.log "Posted"
          .fail ->
              console.log "Failed"

    render: ->
        userDebts = @props.debts.userInvolved @props.user

        selectedGroup = 
            if @state.selectedGroup? then @state.selectedGroup
            else if userDebts.length > 0
                userDebts.models[0].get('group_id')
            else null

        debts =
            if selectedGroup?
                @props.debts
                    .groupIs selectedGroup
                    .userInvolved @props.user
            else []

        titleText = "Welcome to GoDut.ch, #{@props.user.get('username')}"

        return `<div>
                <TitleText text={titleText} />
                <GroupList groups={this.props.groups} selectedGroup={selectedGroup} selectGroup={this.selectGroup} />
                <DebtList debts={debts} user={this.props.user} users={this.props.users} />
                <Settings createDebt={this.createDebt} selectedGroup={selectedGroup} />
            </div>`

TitleText = React.createClass
    render: ->
        return `<div id="logo"><h1>{this.props.text}</h1></div> `

GroupList = React.createClass
    select: (e) ->
        $target = $ e.currentTarget
        groupId = $target.data 'group'
        @props.selectGroup groupId

    render: ->
        groups =
            @props.groups.map (group) =>
                selected = if group.get('id') is @props.selectedGroup then 'selected' else ''
                select = this.select

                `<li key={group.get('id')} className={selected} onClick={select} data-group={group.get('id')}>
                    {group.get('name')}
                    <i className='fa fa-arrow-circle-right'></i>
                </li>`


        return `<div id="overview" className="column narrow">
            <ul>
                <h2>Combined</h2>
                <li>
                    3 People Owe <strong>You</strong> $10
                    <i className='fa fa-arrow-circle-right'></i>
                </li>
                <li>
                    <strong>You</strong> Owe 2 People $18
                    <i className='fa fa-arrow-circle-right'></i>
                </li>
                <h2>Individual Groups</h2>
                {groups}
                <li className="add" onClick={this.select}>
                    <i className='fa fa-plus'></i>
                </li>
            </ul>
        </div>`

DebtList = React.createClass
    render: ->
        debts = 
            if @props.debts.length > 0
                first = true
                _.map @props.debts.groupByUsers(@props.user), (debts, userId) =>
                    otherUser = @props.users.get(userId)
                    user = this.props.user
                    groupId = @props.debts.models[0].get('group_id')

                    key = "#{groupId}.#{userId}"

                    if first
                        first = false
                        open = true
                    else
                        open = false

                    `<DebtView key={key} user={user} otherUser={otherUser} debts={debts} open={open} />`
            else
                `<h2>There are no debts</h2>`

        return `<div id="details" className="column wide">{debts}</div>`

DebtView = React.createClass
    getInitialState: ->
        open: @props.open or false

    componentDidMount: ->
        card = $ @refs.card.getDOMNode()

        if not card.hasClass 'closed'
            height = card.height()
            card.css 'max-height', height
        else
            card.css 'transition', '0s'
            card.removeClass 'closed'
            height = card.height()
            card.addClass 'closed'
            setTimeout (-> card.css 'transition', '1s'), 1
            card.css 'max-height', height

    toggleOpen: ->
        @setState open: (not @state.open)

    render: ->
        debits = @props.debts.debtorIs @props.user
        credits = @props.debts.lenderIs @props.user

        total = credits.totalAmount() - debits.totalAmount()

        if total is 0
            return ``

        absTotal = Math.abs(total)
        cents = absTotal % 100
        cents = if cents is 0 then '00' else if cents < 10 then '0'+cents else cents
        dollars = (absTotal - cents) / 100
        amount = " $#{dollars}.#{cents}"

        titleText =
            if total > 0
                `<span>
                    <em>{this.props.otherUser.get('username')}</em> owes <strong>You</strong>{amount}
                </span>`
            else
                `<span>
                    <strong>You</strong> owe <em>{this.props.otherUser.get('username')}</em>{amount}
                </span>`

        cardClass  = if @state.open then "card" else "closed card"
        toggleIconClass = if @state.open then "fa fa-minus" else "fa fa-plus"

        debtRows =
            @props.debts.map (debt) =>
                sign =
                    if debt.get('debtor_id') is @props.user.id
                        '– '
                    else
                        '+ '

                `<tr>
                    <td>10/01/2014</td>
                    <td>{sign} {debt.get('amount')}</td>
                    <td>{debt.get('description')}</td>
                    <td><i className="fa fa-times"></i></td>
                </tr>`

        return `<div className={cardClass} ref="card">
            <h3 onClick={this.toggleOpen}>
                {titleText}
                <i className={toggleIconClass}></i>
            </h3>
            <table>
                <tr>
                    <th className='date'>Date</th>
                    <th className='amount'>Amount</th>
                    <th>Description</th>
                    <th></th>
                </tr>
                {debtRows}
            </table>
            <div className="payment">
                <button className="green"><i className="fa fa-check"></i>Pay All {amount}</button>
                <button>Pay Other</button>
            </div>
        </div>`

Settings = React.createClass
    createDebt: ->
        getValue = (x) => @refs[x].getDOMNode().value

        user = getValue 'who'
        type = getValue 'type'
        amount = getValue 'amount'
        description = getValue 'description'

        debt =
            user: parseInt user
            description: description
            group: @props.selectedGroup
            amount:
                if (parseInt amount).toString() is "NaN"
                    0
                else if type is 'charge'
                    parseInt amount
                else
                    0 - (parseInt amount)

        @props.createDebt debt

        return false

    render: ->
        return `<div id="user" className="column">
            <div id="new-debt" className="card">
                <h3>
                    New Debt
                    <i className="fa fa-minus"></i>
                </h3>
                <form onSubmit={this.createDebt}>
                    <div>
                        <select ref='type'>
                            <option value="charge">Charge</option>
                            <option value="owe">I Owe</option>
                        </select>
                        <i className='fa fa-caret-down'></i>

                        <select ref='who'>
                            <option value="1">Barnaby Jackson</option>
                            <option value="2">Lee Woodbridge</option>
                        </select>
                        <i className='fa fa-caret-down'></i>

                        <input ref='amount' name="amount" type="text" placeholder="Amount" />
                    </div>

                    <div>
                        <input ref='description' name="description" type="text" placeholder="Description"  className="form-control"/>
                    </div>

                    <div className="create-button">
                        <button>Create</button>
                    </div>
                </form>
            </div>
            <div className="card">
                <h3>
                    Group Members
                    <i className="fa fa-plus"></i>
                </h3>
            </div>
        </div>`


facebookLoginCallback = (response) ->

    groups = new Groups()
    debts = new Debts()
    users = new Users()

    groups.on 'add', (group) =>
        id = group.get('id')

        $.getJSON "/group/#{id}/debts", (response) =>
            for debt in response.debts
                debts.add new Debt debt

        $.getJSON "/group/#{id}/users", (response) =>
            for user in response.users
                users.add new User user

    $.getJSON '/user', (response) ->
        user = new User response.user
        users.add user

        for id in response.user.groups
            $.getJSON "/group/#{id}", (response) =>
                groups.add(new Group response.group)


        React.renderComponent Application(user: user, users: users, groups: groups, debts: debts), $('#main')[0], ->
            setTimeout (->$('body').addClass 'logged-in'), 50


$ ->
    window.fbAsyncInit = ->
        FB.init
          appId      : '422041944562938'
          status     : true
          cookie     : true
          xfbml      : true

        $('#facebook-login').click ->
            FB.login facebookLoginCallback, scope: 'email'

        FB.Event.subscribe 'auth.authResponseChange', (response) ->
          if response.status == 'connected'
              facebookLoginCallback()
          else if response.status == 'not_authorized'
              FB.login (->), scope: 'email'
          else
              FB.login (->), scope: 'email'
    ((d) ->
        id = 'facebook-jssdk'
        ref = d.getElementsByTagName('script')[0]
        if d.getElementById(id) then return
        js = d.createElement('script')
        js.id = id
        js.async = true
        js.src = "//connect.facebook.net/en_US/all.js"
        ref.parentNode.insertBefore js, ref
    )(document)
