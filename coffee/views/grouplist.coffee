{Price} = require './utils/price.coffee'

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

module.exports = {GroupList}
