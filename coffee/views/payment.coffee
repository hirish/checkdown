{Price} = require './utils/price.coffee'

Payment = React.createClass
    render: ->
        total = 0
        `<div className="payment">
            <button className="green"><i className="fa fa-check"></i>Pay All <Price amount={Math.abs(total)} currency="USD" /></button>
            <button>Pay Other</button>
        </div>`

module.exports = {Payment}
