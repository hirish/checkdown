{Price} = require './utils/price.coffee'

LeftPane = React.createClass
    select: (e) ->
        $target = $ e.currentTarget
        userId = $target.data 'user'
        @props.selectUser userId

    render: ->
        users =
            @props.users.map (user) =>
                if user is @props.user then return
                if @props.debts.userInvolved(user).length is 0 then return

                selected = if user is @props.selectedUser then 'selected' else ''
                select = this.select

                `<li key={user.get('id')} className={selected} onClick={select} data-user={user.get('id')}>
                    {user.get('username')}
                    <i className='fa fa-arrow-circle-right'></i>
                </li>`

        `<div className="groupList"><div id="overview">
            <ul>
                <h2>Outstanding</h2>
                {users}
                <li className="add" onClick={this.select}>
                    <i className='fa fa-plus'></i>
                </li>
            </ul>
        </div></div>`

module.exports = {LeftPane}
