{DebtView} = require './debtview.coffee'

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

module.exports = {DebtList}
