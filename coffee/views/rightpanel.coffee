{Settings} = require './settings.coffee'

RightPanel = React.createClass
    getInitialState: ->
        createOpen: if @props.open? then @props.open else true

    componentDidMount: ->
        card = $ @refs.new.getDOMNode()

        height = card.height()
        card.css 'max-height', height

    createDebt: ->
        try
            resetForm = _.once =>
                @setState createOpen: false
                setTimeout (=>
                    @setState createOpen: true
                    resetValue 'amount'
                    resetValue 'description'
                ), 1000

            getValue = (x) => @refs[x].getDOMNode().value
            resetValue = (x) => @refs[x].getDOMNode().value = ""

            debtor = getValue 'who'
            type = getValue 'type'
            amount = getValue 'amount'
            description = getValue 'description'

            # Process debtor; could be user or group
            s = debtor.split ":"
            debtorType = s[0]

            if not (debtorType in ['user', 'group'])
                console.error "Unknown debtor type", debtorType
                return false

            debtorId = parseInt s[1]
            if not debtorId?
                console.error "No debtor ID"
                return false

            debtorIds =
                if debtorType is 'user' then [debtorId]
                else
                    users = @props.users
                        .filter (user) ->
                            debtorId in user.get 'groups'
                    _(users).pluck 'id'

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

            if debtorType is 'group'
                amount = parseInt(amount/debtorIds.length)

            _.each debtorIds, (user) =>
                console.log user
                if user isnt @props.user.get 'id'
                    debt =
                        user: parseInt user
                        description: description
                        amount:
                            if (parseInt amount).toString() is "NaN"
                                0
                            else if type is 'charge'
                                parseInt amount
                            else
                                0 - (parseInt amount)

                    @props.createDebt debt, resetForm

        catch e
            window.e = e
            console.error e
        finally
            return false

    toggleCreateOpen: ->
        @setState createOpen: (not @state.createOpen)

    render: ->
        selectOptions = []

        selectOptions.push `<option disabled>Users</option>`

        @props.users.each (user) =>
            if user isnt @props.user
                selectOptions.push(
                    `<option value={"user:" + user.get('id')} key={"select.user." + user.get('username')}>
                      {user.get('username')}
                    </option>`
                )

        selectOptions.push `<option disabled>Groups</option>`

        @props.groups.each (group) =>
            selectOptions.push(
                `<option value={"group:" + group.get('id')} key={"select.group." + group.get('name')}>
                  {group.get('name')}
                </option>`
            )

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
        </div></div>`

module.exports = {RightPanel}
