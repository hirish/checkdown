{Settings} = require './settings.coffee'

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

module.exports = {RightPanel}
