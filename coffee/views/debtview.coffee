{Price} = require './utils/price.coffee'
{Payment} = require './payment.coffee'

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

                if (@props.settings.paidCutoffDate?) and
                   (@props.settings.paidCutoffDate > Date.parse(debt.get 'created'))
                    return `<tr key={key} />`

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
        </div>`

module.exports = {DebtView}
