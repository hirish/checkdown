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

    groupIs: (group) ->
        groupId = group.get 'id'
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
        @reduce ((x, y) ->
            # if y.get('paid') then x else x + y.get('amount')
            x + y.get('amount')
        ), 0

Groups = Backbone.Collection.extend
    model: Group


##################################################
### Views
##################################################

Application = React.createClass
    getInitialState: ->
        selectedGroup: null
        settings:
            paidCutoffDate: null

    componentWillMount: ->
        @props.groups.on 'add remove', =>
            @forceUpdate()

        @props.debts.on 'add remove', =>
            @forceUpdate()

    selectGroup: (id) ->
        group = @props.groups.get id
        @setState selectedGroup: group

    createDebt: (debt, callback) ->
        $.post "/group/#{@state.selectedGroup.get 'id'}/debts", debt
          .done (response) =>
              @props.debts.add(new Debt JSON.parse response)
              callback()
          .fail ->
              alert "For some reason, we failed to create this debt. Sorry!"
              console.log "Failed"

    updateSettings: (settings) ->
        @setState settings: settings

    render: ->
        userDebts = @props.debts.userInvolved @props.user

        selectedGroup = 
            if @state.selectedGroup? then @state.selectedGroup
            else if userDebts.length > 0
                group_id = userDebts.models[0].get('group_id')
                @props.groups.get group_id
            else null

        @state.selectedGroup = selectedGroup

        selectedGroupUsers =
            if selectedGroup?
                group_id = selectedGroup.get 'id'
                @props.users.filter (user) ->
                    group_id in user.get 'groups'
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
                <div className="container">
                  <GroupList
                    groups={this.props.groups}
                    debts={this.props.debts}
                    user={this.props.user}
                    selectedGroup={selectedGroup}
                    selectGroup={this.selectGroup} />
                  <DebtList
                    debts={debts}
                    user={this.props.user}
                    users={this.props.users}
                    settings={this.state.settings} />
                  <RightPanel
                    createDebt={this.createDebt}
                    user={this.props.user}
                    selectedGroup={selectedGroup}
                    selectedGroupUsers={selectedGroupUsers}
                    settings={this.state.settings}
                    updateSettings={this.updateSettings} />
                </div>
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
                selected = if group is @props.selectedGroup then 'selected' else ''
                select = this.select

                `<li key={group.get('id')} className={selected} onClick={select} data-group={group.get('id')}>
                    {group.get('name')}
                    <i className='fa fa-arrow-circle-right'></i>
                </li>`

        allDebts = @props.debts.debtorIs @props.user
        allLoans = @props.debts.lenderIs @props.user

        countDebts = _.keys(allDebts.groupByUsers @props.user).length
        countLoans = _.keys(allLoans.groupByUsers @props.user).length

        countDebtsText = if countDebts is 1 then "1 Person" else "#{countDebts} People"
        countLoansText = if countLoans is 1 then "1 Person" else "#{countLoans} People"

        totalDebts = allDebts.totalAmount()
        totalLoans = allLoans.totalAmount()


        `<div className="groupList"><div id="overview">
            <ul>
                <h2>Combined</h2>
                <li>
                    {countLoansText} People Owe <strong>You</strong> <Price amount={totalLoans} currency="USD" />
                    <i className='fa fa-arrow-circle-right'></i>
                </li>
                <li>
                    <strong>You</strong> Owe {countDebtsText} <Price amount={totalDebts} currency="USD" />
                    <i className='fa fa-arrow-circle-right'></i>
                </li>
                <h2>Individual Groups</h2>
                {groups}
                <li className="add" onClick={this.select}>
                    <i className='fa fa-plus'></i>
                </li>
            </ul>
        </div></div>`

DebtList = React.createClass
    render: ->
        debts = 
            if @props.debts.length > 0
                first = true
                _.map @props.debts.groupByUsers(@props.user), (debts, userId) =>
                    otherUser = @props.users.get(userId)
                    user = @props.user
                    settings = @props.settings
                    groupId = @props.debts.models[0].get('group_id')

                    key = "#{groupId}.#{userId}"

                    if first
                        first = false
                        open = true
                    else
                        open = false

                    `<DebtView
                        key={key}
                        user={user}
                        otherUser={otherUser}
                        debts={debts}
                        open={open}
                        settings={settings} />`
            else
                `<h2>There are no debts</h2>`

        return `<div className="debtList"><div id="details">{debts}</div></div>`

DebtView = React.createClass
    getInitialState: ->
        open: @props.open or false

    recalculateHeight: ->
        return if not @refs.card
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

    componentDidMount: -> @recalculateHeight()

    toggleOpen: ->
        @setState open: (not @state.open)

    render: ->
        debits = @props.debts.debtorIs @props.user
        credits = @props.debts.lenderIs @props.user

        total = credits.totalAmount() - debits.totalAmount()

        if total is 0
            return `<div></div>`

        titleText =
            if total > 0
                `<span>
                    <em>{this.props.otherUser.get('username')}</em> owes <strong>You</strong> <Price amount={Math.abs(total)} currency="USD" />
                </span>`
            else
                `<span>
                    <strong>You</strong> owe <em>{this.props.otherUser.get('username')}</em> <Price amount={Math.abs(total)} currency="USD" />
                </span>`

        cardClass  = if @state.open then "card" else "closed card"
        toggleIconClass = if @state.open then "fa fa-minus" else "fa fa-plus"

        debtRows =
            @props.debts.map (debt) =>
                key = debt.get 'id'

                if (not @props.settings.paidCutoffDate?) or
                   (@props.settings.paidCutoffDate > Date.parse(debt.get 'created'))
                    if debt.get 'paid' then return `<tr key={key} />`

                lineStyle = if debt.get 'paid' then "paid" else ""

                sign =
                    if debt.get('debtor_id') is @props.user.id
                        '– '
                    else
                        '+ '

                `<tr key={key} className={lineStyle}>
                    <td>{debt.get('created')}</td>
                    <td>{sign} <Price amount={debt.get('amount')} currency="USD" /></td>
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
                <button className="green"><i className="fa fa-check"></i>Pay All <Price amount={Math.abs(total)} currency="USD" /></button>
                <button>Pay Other</button>
            </div>
        </div>`

RightPanel = React.createClass
    getInitialState: ->
        createOpen: if @props.open? then @props.open else true

    componentDidMount: ->
        card = $ @refs.new.getDOMNode()

        height = card.height()
        card.css 'max-height', height

    createDebt: ->
        getValue = (x) => @refs[x].getDOMNode().value
        resetValue = (x) => @refs[x].getDOMNode().value = ""

        user = getValue 'who'
        type = getValue 'type'
        amount = getValue 'amount'
        description = getValue 'description'

        # Process amount
        # Removes non numeric (or '.') characters
        # Turns it into a float
        # Turns it into cents
        # Rounds
        # Fails if it's not still a number
        amount = Math.round(parseFloat(amount.replace(/[^0-9.]/g, ''))*100)
        if isNaN amount
            console.error "OMG that's not a number"
            return false

        debt =
            user: parseInt user
            description: description
            group: @props.selectedGroup.get 'id'
            amount:
                if (parseInt amount).toString() is "NaN"
                    0
                else if type is 'charge'
                    parseInt amount
                else
                    0 - (parseInt amount)

        callback = =>
            @setState createOpen: false
            setTimeout (=>
                @setState createOpen: true
                resetValue 'amount'
                resetValue 'description'
            ), 1000

        @props.createDebt debt, callback

        return false

    toggleCreateOpen: ->
        @setState createOpen: (not @state.createOpen)

    render: ->
        selectOptions = 
            if @props.selectedGroupUsers?
                @props.selectedGroupUsers.map (user) ->
                  `<option value={user.get('id')} key={"select." + user.get('username')}>
                      {user.get('username')}
                  </option>`
            else
                ''

        groupMembers =
            if @props.selectedGroupUsers?
                @props.selectedGroupUsers.map (user) ->
                    image = "http://gravatar.com/avatar/#{user.get('gravatar')}.png"
                    `<div className="userList" key={"member." + user.get('username')}>
                      <img src={image} className="avatar" />
                      {user.get('username')} - <em>{user.get('email')}</em>
                    </div>`
            else
                ''

        cardClass  = if @state.createOpen then "card" else "closed card"
        toggleIconClass = if @state.createOpen then "fa fa-minus" else "fa fa-plus"

        return `<div className="aside"><div id="user">
            <div id="new-debt" ref="new" className={cardClass}>
                <h3>
                    New Debt
                    <i className={toggleIconClass} onClick={this.toggleCreateOpen}></i>
                </h3>
                <form onSubmit={this.createDebt} className="createDebt">
                    <div>
                        <select ref='type'>
                            <option value="charge">Charge</option>
                            <option value="owe">I Owe</option>
                        </select>
                        <i className='fa fa-caret-down'></i>

                        <select ref='who' className="who">{selectOptions}</select>
                        <i className='fa fa-caret-down'></i>

                        <input ref='amount' name="amount" type="text" placeholder="Amount" className="amount" />
                    </div>

                    <div>
                        <input ref='description' name="description" type="text" placeholder="Description"  className="description" />
                    </div>

                    <div className="create-button">
                        <button>Create</button>
                    </div>
                </form>
            </div>
            <Settings settings={this.props.settings} updateSettings={this.props.updateSettings} />
            <div className="card">
                <h3>Group Members</h3>
                {groupMembers}
            </div>
        </div></div>`

Settings = React.createClass
    componentDidMount: ->
        $(@refs.paidCutoffDate.getDOMNode()).mask '99 / 99 / 9999'

    updatePaidCutoff: (never) ->
        =>
            newCutoff = Date.parse @refs.paidCutoffDate.getDOMNode().value

            settings = @props.settings
            settings.paidCutoffDate = if never or isNaN(newCutoff) then null else newCutoff

            @props.updateSettings settings

    focusOnCutoff: ->
        $(@refs.paidCutoffDate.getDOMNode()).focus()

    render: ->
        neverPaid = @props.settings.paidCutoffDate?

        `<div className="card settings">
            <h3>Settings</h3>
            <div>Show paid debts from:</div>
            <div>
                <input type="radio" name="paidCutoff" checked={!neverPaid} onChange={this.updatePaidCutoff(true)} />
                <label>Never ever</label>

                <input type="radio" name="paidCutoff" checked={neverPaid} onChange={this.focusOnCutoff} />
                <label>
                  <input type="text" placeholder="MM / DD / YYYY" ref="paidCutoffDate" onKeyUp={this.updatePaidCutoff(false)} />
                </label>
            </div>
        </div>`


Price = React.createClass
  render: ->
    switch @props.currency
      when 'USD'
        code = 'USD'
        symbol = String.fromCharCode 36
      when 'EUR'
        code = 'EUR'
        symbol = String.fromCharCode 8364
      when 'GBP'
        code = 'GBP'
        symbol = String.fromCharCode 163
      else
        code = 'USD'
        symbol = String.fromCharCode 36

		# Amount is passed in cents
    amount = Number(@props.amount/100).toFixed(2)

    code = ' ' + code

    if @props.hideCurrency? then code = ''

    `<span>{symbol}{amount}{code}</span>`



facebookLoginCallback = (response) ->

    groups = new Groups()
    debts = new Debts()
    users = new Users()

    groups.on 'add', (group) =>
        id = group.get('id')

        $.getJSON "/group/#{id}/debts", (response) ->
            returned_debts = _.map response.debts, (debt) -> new Debt debt
            debts.add returned_debts

        $.getJSON "/group/#{id}/users", (response) ->
            returned_users = _.map response.users, (user) -> new User user
            users.add returned_users

    $.getJSON '/user', (response) ->
        user = new User response.user
        users.add user

        for id in response.user.groups
            $.getJSON "/group/#{id}", (response) =>
                groups.add(new Group response.group)


        window.app = React.renderComponent Application(user: user, users: users, groups: groups, debts: debts), $('#main')[0], ->
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

  window.f = ->
    facebookLoginCallback()
