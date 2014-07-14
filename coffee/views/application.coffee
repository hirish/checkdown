{TitleText} = require './titletext.coffee'
{LeftPane} = require './grouplist.coffee'
{DebtList} = require './debtlist.coffee'
{RightPanel} = require './rightpanel.coffee'
{Users} = require '../models/user.coffee'
{Debt} = require '../models/debt.coffee'

Application = React.createClass
    getInitialState: ->
        selectedUser: null
        settings:
            paidCutoffDate: null

    componentWillMount: ->
        @props.groups.on 'add remove', =>
            @forceUpdate()

        @props.debts.on 'add remove', =>
            @forceUpdate()

        @props.users.on 'add remove', =>
            @forceUpdate()

    selectUser: (id) ->
        user = @props.users.get id
        @setState selectedUser: user

    createDebt: (debt, callback) ->
        $.post "/debts", debt
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

        usersWithDebts = new Users @props.users.filter (user) =>
            user isnt @props.user and userDebts.userInvolved(user).length > 0

        selectedUser =
            if @state.selectedUser? then @state.selectedUser
            else if @props.users.length > 0 then usersWithDebts.models[0]
            else null

        selectedGroupUsers = null
            # if selectedGroup?
            #     group_id = selectedGroup.get 'id'
            #     @props.users.filter (user) ->
            #         group_id in user.get 'groups'
            # else null

        debts =
            if selectedUser?
                @props.debts
                    .userInvolved @props.user
                    .userInvolved selectedUser
            else []

        titleText = "Welcome to GoDut.ch, #{@props.user.get('username')}"

        `<div>
            <TitleText text={titleText} />
            <div className="container">
              <LeftPane
                users={this.props.users}
                debts={this.props.debts}
                user={this.props.user}
                selectedUser={selectedUser}
                selectUser={this.selectUser} />
              <DebtList
                debts={debts}
                user={this.props.user}
                users={this.props.users}
                settings={this.state.settings} />
              <RightPanel
                createDebt={this.createDebt}
                user={this.props.user}
                users={this.props.users}
                groups={this.props.groups}
                settings={this.state.settings}
                updateSettings={this.updateSettings} />
            </div>
        </div>`

module.exports = {Application}
