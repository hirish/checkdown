{TitleText} = require './titletext.coffee'
{GroupList} = require './grouplist.coffee'
{DebtList} = require './debtlist.coffee'
{RightPanel} = require './rightpanel.coffee'

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

module.exports = {Application}
